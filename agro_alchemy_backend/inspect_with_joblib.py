import joblib
import traceback

try:
    model = joblib.load('pest_fertilizers.pkl')
    with open('inspect_out2.txt', 'w', encoding='utf-8') as out_f:
        out_f.write(f"Model type: {type(model)}\n")
        if hasattr(model, 'feature_names_in_'):
            out_f.write(f"Feature names: {model.feature_names_in_}\n")
        if hasattr(model, 'classes_'):
            out_f.write(f"Classes: {model.classes_}\n")
except Exception as e:
    with open('inspect_out2.txt', 'w', encoding='utf-8') as out_f:
        traceback.print_exc(file=out_f)
