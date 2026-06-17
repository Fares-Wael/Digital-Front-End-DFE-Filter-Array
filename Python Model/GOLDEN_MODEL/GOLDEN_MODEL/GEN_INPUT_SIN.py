import numpy as np

# ==========================================
# إعدادات الإشارة (Sine Wave Generator)
# ==========================================
Fs = 9e6               # تردد العينات: 9 ميجا هرتز
Duration = 0.0003      # المدة: 300 ميكرو ثانية (كافية جداً)
N = int(Fs * Duration)  # عدد العينات
t = np.arange(N) / Fs

# تردد الموجة: 1 ميجا هرتز (عشان تعدي من الفلتر)
freq = 1.0e6
amp = 0.9      # سعة عالية عشان نشوف الإشارة بوضوح

# معادلة الموجة
signal = amp * np.sin(2 * np.pi * freq * t)

# ==========================================
# التحويل لـ Fixed-Point (Hex Format)
# ==========================================
SCALE = 2**15
signal_fixed = np.round(signal * SCALE).astype(int)
signal_fixed = np.clip(signal_fixed, -32768, 32767)

# الحفظ في ملف input_data.txt
with open("input_data.txt", "w") as f:
    for val in signal_fixed:
        # تحويل الرقم لـ Hex (4 خانات) عشان الـ Verilog يقراه
        # val & 0xFFFF بيعالج الأرقام السالبة صح
        f.write(f"{val & 0xFFFF:04X}\n")

print(f"✅ تم إنشاء ملف 'input_data.txt' بنجاح!")
print(f"   - يحتوي على {N} عينة.")
print(f"   - التردد: {freq/1e6} MHz")
