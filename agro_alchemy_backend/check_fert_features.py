import pickle

with open('pest_fertilizers.pkl', 'rb') as f:
    ml_model = pickle.load(f)

with open('fert_features.txt', 'w', encoding='utf-8') as f:
    if hasattr(ml_model['fertilizer_model'], 'feature_names_in_'):
        f.write(f"Fert features: {list(ml_model['fertilizer_model'].feature_names_in_)}\n")
    else:
        f.write("No feature names in fertilizer model\n")
