# NEXUS App

Mobile application for the **NEXUS IoT security system**, a connected anti-theft module for two-wheeled vehicles (bikes, scooters, e-bikes).

## Team Members

- Djibril Djou Kenne
- Quentin Faury
- Cassandra Sopp

## Project Overview

NEXUS is an IoT project designed to improve the security of two-wheeled vehicles through:

- Motion detection (IMU)
- Human presence detection (PIR)
- Image capture using a Raspberry Pi camera
- Real-time notifications
- Cloud synchronization with Supabase
- Mobile monitoring application

## Features

- User authentication
- Real-time alerts
- Alert history
- Image storage
- Module monitoring
- Battery level monitoring
- Module-to-user association

### Mobile
- Flutter
- Dart

### Backend / Cloud
- Supabase
- PostgreSQL
- Authentication API

### Embedded System
- Raspberry Pi 4
- PIR HC-SR501
- MPU6050 IMU
- Raspberry Pi Camera Module 3

## Installation

```bash
git clone https://github.com/your-username/nexus_app.git
cd nexus_app
flutter pub get
flutter run
```


