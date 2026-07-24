import os
import re

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


from transformers import Trainer, TrainingArguments, AutoTokenizer, AutoModelForSequenceClassification
import torch.nn as nn
import torch
from torch.utils.data import Dataset, DataLoader

from sklearn.metrics import accuracy_score, precision_recall_fscore_support
from sklearn.model_selection import train_test_split
from sklearn.utils import resample
from tqdm import tqdm

from datasets import Dataset, load_dataset, DatasetDict, Features, ClassLabel, Value
import evaluate

from sklearn.metrics import confusion_matrix

from importlib.metadata import version

import transformers, datasets,  sklearn
from pathlib import Path
import accelerate

print("Loaded library versions:")
print(" torch", torch.__version__)
print(" transformers", transformers.__version__)
print(" datasets", datasets.__version__)
print(" evaluate", evaluate.__version__)
print(" scikit-learn", sklearn.__version__)
print(" pandas", pd.__version__)
print(" numpy", np.__version__)
print(" accelerate", accelerate.__version__)

# path parameterized: BERT model/scratch root (original: external SSD PATH_TO_BERT_MODEL_STORE).
# Set env var BERT_WORK_ROOT to redirect. Expects pbcompanies.csv + pbmarketmap_v2.csv here too.
DIR = Path(os.environ.get("BERT_WORK_ROOT", "PATH_TO_BERT_MODEL_STORE"))

print(torch.backends.mps.is_available())

def subsegment_name_processing(nameStr):
    # str.replace(r'[^\w\s]|_', '', regex=True).str.replace(" ", "", regex=False)
    nameStr = re.sub(r'[^\w\s]|_', '', nameStr)
    return nameStr.replace(" ", "")

def trainit(i,df_pb_company,df_market_map,df_subsegment,ls_subsegment):
    SELECTED_SUBSEGMENT = ls_subsegment[i]
    ## Generate label
    df_market_map['label'] = None
    df_market_map.loc[df_market_map['fullname'].isin([SELECTED_SUBSEGMENT]), 'label'] = 1
    df_market_map.loc[~df_market_map['fullname'].isin([SELECTED_SUBSEGMENT]), 'label'] = 0
    df_market_map['description'] = df_market_map['description'].str.lower()
    PARENT_SEGMENT = df_subsegment[df_subsegment['fullname'] == SELECTED_SUBSEGMENT]['segment'].values[0]
    NUM_SAMPLED = 15
    ADJACENT_THRESHOLD = 100
    print('working on ' + str(i) + ': ' + SELECTED_SUBSEGMENT)
    
    # Generate Training and Validation Set
    
    ## Processing Negative Samples: Filter negative samples from adjacent subsegments
    ds_negatives_adjacent_subsegments = df_market_map[(df_market_map.label == 0) & (df_market_map.segment == PARENT_SEGMENT)]
    if len(ds_negatives_adjacent_subsegments) > ADJACENT_THRESHOLD:
        ds_negatives_adjacent_subsegments = ds_negatives_adjacent_subsegments.sample(ADJACENT_THRESHOLD, replace=True)
    ds_negatives_downsample = df_market_map[df_market_map.label == 0].groupby('segment', group_keys=False).apply(lambda x: x.sample(NUM_SAMPLED, replace=True))
    ds_negatives = pd.concat([ds_negatives_adjacent_subsegments, ds_negatives_downsample]).drop_duplicates()
    
    ## Processing Positive Samples
    ds_positives = df_market_map[df_market_map.label == 1]   
    
    ## Train test split
    negativeTrain, negativeValidTest = train_test_split(ds_negatives, test_size=0.2)
    negativeValid, negativeTest = train_test_split(negativeValidTest, test_size=0.5)
    positiveTrain, positiveValidTest = train_test_split(ds_positives, test_size = 0.2)
    positiveValid, positiveTest = train_test_split(positiveValidTest, test_size=0.5)
    TrainDf = pd.concat([negativeTrain, positiveTrain]).drop(['companyid','marketmap', 'segment', 'subsegment'], axis = 1).reset_index(drop=True)
    ValidationDf = pd.concat([negativeValid, positiveValid]).drop(['companyid','marketmap', 'segment', 'subsegment'], axis = 1).reset_index(drop=True)
    TestDf = pd.concat([negativeTest, positiveTest]).drop(['companyid','marketmap', 'segment', 'subsegment'], axis = 1).reset_index(drop=True)
    datasetImbalancedTest = df_market_map.sample(1500).drop(['companyid','marketmap', 'segment', 'subsegment'], axis = 1).reset_index(drop=True)
    
    ## Outside prediction set
    df_pb_company = df_pb_company[df_pb_company['description'].str.len() > 0]
    ds_out = df_pb_company[['description','companyid']].reset_index(drop=True)
    ds_out['label'] = 0
    ds_out['description'] = ds_out['description'].str.lower()
    
    ## Dataset generated
    datasets_ds = DatasetDict({
        "train": Dataset.from_pandas(TrainDf).class_encode_column('label').shuffle(),
        "test": Dataset.from_pandas(TestDf).class_encode_column('label').shuffle(),
        "valid": Dataset.from_pandas(ValidationDf).class_encode_column('label').shuffle(),
        "imbaTest":  Dataset.from_pandas(datasetImbalancedTest).class_encode_column('label'),
        #"out": Dataset.from_pandas(ds_out).class_encode_column('label').shuffle(),
    })

    ##Tokenizer and model
    def tokenize_function(dataset):
        return tokenizer(dataset["description"], padding="max_length", truncation=True)
    tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")
    tokenized_datasets_ds = datasets_ds.map(tokenize_function, batched=True)
    model_downsampled = AutoModelForSequenceClassification.from_pretrained("bert-base-uncased", num_labels=2)
    
    ## Create directories if they don't exist
    model_dir = DIR / "pbmarketmap_v2/model/SUBSEGMENT-{}".format(subsegment_name_processing(SELECTED_SUBSEGMENT))
    logs_dir = DIR / "pbmarketmap_v2/model/SUBSEGMENT-{}/logs".format(subsegment_name_processing(SELECTED_SUBSEGMENT))
    positive_dir = DIR / "pbmarketmap_v2/positive"
    
    model_dir.mkdir(parents=True, exist_ok=True)
    logs_dir.mkdir(parents=True, exist_ok=True)
    positive_dir.mkdir(parents=True, exist_ok=True)
   
    ## Training Settings
    training_args = TrainingArguments(
        output_dir=model_dir, 
        evaluation_strategy="epoch", 
        num_train_epochs=5,
        gradient_accumulation_steps=16, 
        per_device_train_batch_size=2,
        save_strategy='no',  # Only save the final result
        logging_dir=logs_dir,  # Directory to save TensorBoard logs
        logging_steps=10,  # Log metrics every 10 steps
        report_to = "none",
        use_mps_device = True
    )

    ## Evaluation Metrics
    metric = evaluate.combine(["accuracy", "recall", "precision", "f1"])
    def compute_metrics(eval_pred):
        logits, labels = eval_pred
        predictions = np.argmax(logits, axis=-1)
        return metric.compute(predictions=predictions, references=labels)
    ## Train
    trainer_downsampled = Trainer(
        model=model_downsampled,
        args=training_args,
        train_dataset=tokenized_datasets_ds["train"],
        eval_dataset=tokenized_datasets_ds["valid"],
        compute_metrics=compute_metrics,
    )

    trainer_downsampled.train()
    trainer_downsampled.evaluate()

    # Save the evaluation metrics for the validation set
    trainer_downsampled.save_metrics('eval', trainer_downsampled.evaluate())

    # Evaluate the model on the test set
    test_eval_results = trainer_downsampled.evaluate(eval_dataset=tokenized_datasets_ds["test"])

    # Save the evaluation metrics for the test set
    trainer_downsampled.save_metrics('test', test_eval_results)

    trainer_downsampled.save_model(model_dir)

    # #Predict
    # out_predictions = trainer_downsampled.predict(tokenized_datasets_ds["out"])
    # y_pred = out_predictions.predictions
    # y_neg = out_predictions.predictions[:, 0]
    # y_pos = out_predictions.predictions[:, 1]
    # y_pred_dummy = np.argmax(y_pred, axis = -1)

    # df=pd.DataFrame(data={'pred_pos':y_pos,'pred_neg':y_neg,'positive':y_pred_dummy,'description':tokenized_datasets_ds["out"]['description'],'companyid':tokenized_datasets_ds["out"]['companyid']})

    # df.to_csv(positive_dir / "{}_positive_bert.csv".format(subsegment_name_processing(SELECTED_SUBSEGMENT)))

    print(SELECTED_SUBSEGMENT+'finished')



df_pb_company = pd.read_csv(DIR / 'pbcompanies.csv')
df_market_map = pd.read_csv(DIR /'pbmarketmap_v2.csv')

df_market_map = df_market_map[~(df_market_map['description'].isna())]
df_subsegment = df_market_map.groupby(["marketmap","segment","subsegment"],as_index=False)[["companyid"]].count()
df_subsegment['fullname'] = df_subsegment['marketmap'] + '|' + df_subsegment['segment'] + '|' + df_subsegment['subsegment']
df_market_map['fullname'] = df_market_map['marketmap'] + '|' + df_market_map['segment'] + '|' + df_market_map['subsegment']
ls_subsegment = df_subsegment['fullname'].to_list()
start = 288
end = 298
error_list = []
finished_list = []

import traceback, logging, sys
logging.basicConfig(filename=DIR / "train_errors.log", level=logging.ERROR)



for i in range(start,end):
    try:
        trainit(i,df_pb_company,df_market_map,df_subsegment,ls_subsegment)
        finished_list.append(i)
    except Exception as e:
        error_list.append(i)
        logging.error("Sub-segment %s failed\n%s", i, traceback.format_exc())
        print(f"Sub-segment {i} failed:", e, file=sys.stderr)
