import pickle
import traceback

try:
    with open('pest_fertilizers.pkl', 'rb') as f:
        model = pickle.load(f)
    print("Model type:", type(model))
    if hasattr(model, 'feature_names_in_'):
        print("Feature names:", model.feature_names_in_)
    if hasattr(model, 'classes_'):
        print("Classes:", model.classes_)
except Exception as e:
    traceback.print_exc()
