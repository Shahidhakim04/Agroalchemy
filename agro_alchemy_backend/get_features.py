import pickle

with open('pest_fertilizers.pkl', 'rb') as f:
    ml_model = pickle.load(f)

with open('features_out.txt', 'w', encoding='utf-8') as f:
    f.write(f"Number of features: {ml_model['scaler'].n_features_in_}\n")
    f.write(f"Features: {ml_model['features']}\n")
    if hasattr(ml_model['scaler'], 'feature_names_in_'):
        f.write(f"Scaler features in: {list(ml_model['scaler'].feature_names_in_)}\n")
    f.write(f"Crop model features in: {ml_model['crop_model'].n_features_in_}\n")
    f.write(f"Fertilizer model features in: {ml_model['fertilizer_model'].n_features_in_}\n")
