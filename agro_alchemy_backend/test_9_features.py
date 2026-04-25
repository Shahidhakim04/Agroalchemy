import pickle
import numpy as np

with open('pest_fertilizers.pkl', 'rb') as f:
    ml_model = pickle.load(f)

district = 'Pune'
soil_color = 'Black'
crop = 'Wheat'
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
crop_enc = safe_transform(ml_model['crop_encoder'], crop)

features = [[district_enc, soil_enc, n, p, k, ph, rainfall, temp]]
scaled_features = ml_model['scaler'].transform(features)

fert_features = np.column_stack((scaled_features, [crop_enc]))

fert_pred = ml_model['fertilizer_model'].predict(fert_features)
recommended_fertilizer = ml_model['fertilizer_encoder'].inverse_transform(fert_pred)[0]

with open('fert_test_out.txt', 'w', encoding='utf-8') as f:
    f.write(f"Fertilizer: {recommended_fertilizer}\n")
    
# also test with unscaled features
fert_features_unscaled = [[district_enc, soil_enc, n, p, k, ph, rainfall, temp, crop_enc]]
fert_pred2 = ml_model['fertilizer_model'].predict(fert_features_unscaled)
rec_fert2 = ml_model['fertilizer_encoder'].inverse_transform(fert_pred2)[0]

with open('fert_test_out.txt', 'a', encoding='utf-8') as f:
    f.write(f"Fertilizer (unscaled): {rec_fert2}\n")

