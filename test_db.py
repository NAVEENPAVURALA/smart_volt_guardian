import firebase_admin
from firebase_admin import credentials, firestore
try:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    doc = db.collection('telemetry').document('latest_state').get()
    print("Database connection SUCCESS!")
    print(f"Latest State: {doc.to_dict()}")
except Exception as e:
    print(f"Error: {e}")
