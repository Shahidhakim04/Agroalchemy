import pickle
import traceback

try:
    with open('pest_fertilizers.pkl', 'rb') as f:
        model = pickle.load(f)
    with open('inspect_out.txt', 'w', encoding='utf-8') as out_f:
        out_f.write(f"Crop encoder classes: {list(model['crop_encoder'].classes_)}\n")
        out_f.write(f"Fertilizer encoder classes: {list(model['fertilizer_encoder'].classes_)}\n")
except Exception as e:
    with open('inspect_out.txt', 'w', encoding='utf-8') as out_f:
        traceback.print_exc(file=out_f)
