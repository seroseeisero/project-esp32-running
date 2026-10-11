# Gait Alert — แอป Flutter แจ้งเตือนท่าวิ่งแบบเรียลไทม์

แอปรับข้อมูลจากเครือข่ายเซนเซอร์ผ่าน BLE แล้วแสดงแรงกดฝ่าเท้าแบบเรียลไทม์
ตอนนี้ **ยังไม่ได้ต่อเซนเซอร์จริง** — ใช้ตัวจำลองข้อมูล (`MockSensorService`) เพื่อทดสอบหน้าจอและเมนูทั้งหมด

## ฮาร์ดแวร์ตามเอกสารโครงงาน

| โหนด | เซนเซอร์ | ESP32 |
|------|----------|-------|
| 1 แผ่นรองเท้า | FSR **5 จุด** (เดิม 4 จุด) | ตัวที่ 1 |
| 2 เคลื่อนไหว | IMU 6-DOF ที่ L5-S1 | ตัวที่ 2 |

ตำแหน่ง FSR: FSR1 ส้นเท้า · FSR2 ฝ่าเท้าด้านนอก · FSR3 จมูกเท้าด้านใน · FSR4 นิ้วโป้งเท้า · **FSR5 อุ้งเท้าด้านใน (ใหม่)**

> ฮาร์ดแวร์: ต้องใช้ ADC ภายนอกที่รองรับตั้งแต่ 5 ช่อง (เช่น ADS1115 สองตัว หรือชิป 8 ช่อง) ตามที่ระบุในเอกสาร

## วิธีรัน

โฟลเดอร์นี้มีเฉพาะโค้ด Dart (`lib/`, `pubspec.yaml`) ยังไม่มีโฟลเดอร์ android/ios ให้สร้างก่อน:

```bash
cd gait_alert
flutter create --platforms=android,ios .   # สร้างโฟลเดอร์แพลตฟอร์ม (ไม่ทับ lib/ ของเรา)
flutter pub get
flutter run
```

ถ้า `flutter create` สร้าง `test/widget_test.dart` เดิมที่อ้างถึง `MyApp` ให้ลบไฟล์นั้นทิ้ง

## หน้าจอและเมนู

| ส่วน | ไฟล์ | หน้าที่ |
|------|------|---------|
| แท็บ เรียลไทม์ | `pages/live_page.dart` | Heatmap แรงกดฝ่าเท้า 5 จุด + CoP, แรงกดสูงสุด, Cadence, ระยะทาง, เริ่ม/หยุดเซสชัน |
| แท็บ เคลื่อนไหว | `pages/motion_page.dart` | Pelvic Drop, Torso Rotation, Vertical Oscillation, Tilt พร้อมกราฟ |
| แท็บ ประวัติ | `pages/history_page.dart` | Dashboard สรุปหลังวิ่ง + รายละเอียดแต่ละเซสชัน |
| แท็บ อุปกรณ์ | `pages/device_page.dart` | สแกน/เชื่อมต่อ BLE 2 โหนด, ความหน่วง, แพ็กเก็ตสูญหาย |
| เมนู Drawer | `alerts_page`, `profile_page`, `settings_page` | แจ้งเตือน, โปรไฟล์ + Personalized Baseline, ตั้งค่า |

## ตรรกะแจ้งเตือน (Sensor Fusion) — `state/app_state.dart`

ประเมินทุกครั้งที่เท้าหลุดพื้น (จบหนึ่งก้าว):

- **เหนื่อยล้า**: Pelvic Drop เกิน 75% ของเกณฑ์ **และ** สัดส่วนแรงที่อุ้งเท้า (FSR5/แรงรวม) เกิน 80% ของเกณฑ์ พร้อมกัน
- **สะโพกตก**: Pelvic Drop เกินเกณฑ์
- **อุ้งเท้ายุบ/เท้าบิดเข้าใน (Overpronation)**: สัดส่วนแรง FSR5 เกินเกณฑ์ (ถ้ามี Baseline ใช้ค่าเฉพาะบุคคล × 1.35)
- **โน้มตัวมากไป**: Tilt เกินเกณฑ์

เตือนซ้ำชนิดเดียวกันได้ไม่ถี่กว่า 15 วินาที มีทั้ง SnackBar, สั่น และเสียง (ปิดได้ในตั้งค่า)
ตัวจำลองจะทำให้ผู้วิ่ง "เหนื่อย" ขึ้นเรื่อย ๆ ภายใน ~3 นาที จึงเห็นแจ้งเตือนจริงตอนทดสอบ

## ต่อเซนเซอร์จริงภายหลัง

ทั้งแอปคุยกับ `SensorService` (`services/sensor_service.dart`) เท่านั้น:

1. เปิด `flutter_blue_plus` ใน `pubspec.yaml` และตั้ง permission BLE (Android: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`; iOS: `NSBluetoothAlwaysUsageDescription`)
2. เติม `services/ble_sensor_service.dart` — ใส่ UUID ให้ตรงเฟิร์มแวร์ แล้วเรียก `parseFootPacket` / `parseMotionPacket` ใน notify
3. แก้ `main.dart` บรรทัดเดียว: `AppState(MockSensorService())` → `AppState(BleSensorService())`

รูปแบบแพ็กเก็ตที่เสนอ (ปรับได้): โหนด 1 = `uint32 timestamp + uint16 x5 (ADC)`, โหนด 2 = `uint32 timestamp + int16 x4 (×100)`
ค่าแรงกดสเกลจาก ADC 12-bit (0–4095) — ถ้าได้ค่าจริงจากการสอบเทียบเป็นนิวตัน ให้แก้ที่ `FootFrame.norm`

## ยังไม่ได้ทำ

- Firebase (Authentication / Firestore) — ตอนนี้ประวัติและโปรไฟล์เก็บในหน่วยความจำ จะหายเมื่อปิดแอป
- การต่อ BLE จริง (มีโครงและตัว parse ไว้แล้ว)
- ข้อมูลในไฟล์นี้ยังไม่ได้ทดลองรันบนเครื่อง เพราะสภาพแวดล้อมที่เขียนโค้ดไม่มี Flutter SDK
