import pickle
import traceback

with open('pest_fertilizers.pkl', 'rb') as f:
    ml_model = pickle.load(f)

try:
    district = 'Pune'
    soil_color = 'Black'
    n, p, k = 100.0, 50.0, 50.0
    ph, rainfall, temp = 6.5, 100.0, 25.0
    
    def safe_transform(encoder, value):
        if value in encoder.classes_:
            return encoder.transform([value])[0]
        for c in encoder.classes_:
            if str(c).lower() == str(value).lower():
                return encoder.transform([c])[0]
        return 0

    district_enc = safe_transform(ml_model['label_encoders']['District_Name'], district)
    soil_enc = safe_transform(ml_model['label_encoders']['Soil_color'], soil_color)
    
    features = [[district_enc, soil_enc, n, p, k, ph, rainfall, temp]]
    scaled_features = ml_model['scaler'].transform(features)
    
    crop_pred = ml_model['crop_model'].predict(scaled_features)
    recommended_crop = ml_model['crop_encoder'].inverse_transform(crop_pred)[0]
    
    fert_pred = ml_model['fertilizer_model'].predict(scaled_features)
    recommended_fertilizer = ml_model['fertilizer_encoder'].inverse_transform(fert_pred)[0]
    
    print("Crop:", recommended_crop)
    print("Fertilizer:", recommended_fertilizer)

except Exception as e:
    traceback.print_exc()
