from fastapi import FastAPI
from pydantic import BaseModel
import pickle
import joblib
import numpy as np
import pandas as pd

# Load the trained model
with open("loan_model.pkl", "rb") as f:
    model = pickle.load(f)

# Initialize FastAPI
app = FastAPI()

# Define Loan Application schema
class LoanApplication(BaseModel):
    Age: int
    Income: int
    LoanAmount: int
    CreditScore: int
    MonthsEmployed: int
    NumCreditLines: int
    InterestRate: float
    LoanTerm: int
    Education: str
    EmploymentType: str
    MaritalStatus: str
    HasMortgage: str
    HasDependents: str
    LoanPurpose: str
    HasCoSigner: str
    Default: str  # Accept "Yes" or "No" from user

# Expected column order from training
expected_columns = [
    'Age', 'Income', 'LoanAmount', 'CreditScore', 'MonthsEmployed', 'NumCreditLines',
    'InterestRate', 'LoanTerm', 'DTIRatio',
    "Education_Bachelor's", "Education_High School", "Education_Master's", "Education_PhD",
    'EmploymentType_Full-time', 'EmploymentType_Part-time', 'EmploymentType_Self-employed', 'EmploymentType_Unemployed',
    'MaritalStatus_Divorced', 'MaritalStatus_Married', 'MaritalStatus_Single',
    'HasMortgage_No', 'HasMortgage_Yes', 'HasDependents_No', 'HasDependents_Yes',
    'LoanPurpose_Auto', 'LoanPurpose_Business', 'LoanPurpose_Education', 'LoanPurpose_Home', 'LoanPurpose_Other',
    'HasCoSigner_No', 'HasCoSigner_Yes', 'Default_0', 'Default_1'
]

# Function to preprocess user input
def preprocess_input(application: LoanApplication):
    try:
        # Convert input to DataFrame
        df = pd.DataFrame([application.dict()])

        # Handle division by zero for DTIRatio
        df['DTIRatio'] = df['LoanAmount'] / (df['Income'] + 1e-6)

        # Convert Default to integer (Yes -> 1, No -> 0)
        df['Default'] = df['Default'].map({"No": 0, "Yes": 1})

        # One-hot encode categorical columns
        categorical_cols = ['Education', 'EmploymentType', 'MaritalStatus', 'HasMortgage', 
                            'HasDependents', 'LoanPurpose', 'HasCoSigner', 'Default']
        df_encoded = pd.get_dummies(df, columns=categorical_cols)

        # Ensure all columns exist (add missing columns with 0s)
        for col in expected_columns:
            if col not in df_encoded.columns:
                df_encoded[col] = 0

        # Match the column order
        df_encoded = df_encoded[expected_columns]

        return df_encoded.values
    
    except Exception as e:
        raise ValueError(f"Error in preprocessing input: {e}")

@app.post("/predict")
def predict_loan(application: LoanApplication):
    try:
        # Convert input to numerical features
        features = preprocess_input(application)

        # Make prediction
        prediction = model.predict(features)[0]

        # Return response
        return {"loan_approval": "Approved" if prediction == 1 else "Rejected"}

    except Exception as e:
        return {"error": str(e)}
