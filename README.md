> 🇹🇷 Türkçe açıklama aşağıdadır. / Turkish description is below.

---

# MetuFit

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge"/>
</p>

A full-stack fitness tracking application featuring daily nutrition logging, GPS activity tracking, and social group features.

---

## Features

- **Nutrition Tracking** — Log daily meals by meal type (breakfast, lunch, dinner, snack), track calories and macros (protein, carbs, fat)
- **Calorie Dashboard** — Animated ring chart showing consumed vs. goal calories, burned calories from activities
- **Activity Tracking** — GPS-based route recording with real-time map, distance, duration and calorie calculation
- **Social Groups** — Create or join groups with invite codes, share meal and activity posts, like and comment
- **Monthly Calendar** — Visual calendar showing daily calorie intake per day, tap any day to jump to it
- **Profile & Goals** — Set daily calorie goal, height, weight, age — updates reflect on dashboard instantly
- **Background Prefetch** — Last 30 days of data loaded silently on startup for instant day navigation
- **Offline Awareness** — Connectivity banner when internet is lost
- **JWT Auth** — Secure login with automatic token refresh

---

## Tech Stack

### Mobile (Flutter)
| Layer | Technology |
|---|---|
| Language | Dart 3 |
| State Management | Flutter Riverpod |
| Navigation | GoRouter |
| HTTP Client | Dio + Auth Interceptor |
| Secure Storage | flutter_secure_storage |
| Maps | flutter_map + OpenStreetMap |
| Location | Geolocator |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter) |

### Backend (Python)
| Layer | Technology |
|---|---|
| Framework | FastAPI |
| ORM | SQLAlchemy (async) |
| Database | PostgreSQL 16 |
| Migrations | Alembic |
| Auth | JWT (access + refresh tokens) |
| File Storage | MinIO |
| Server | Uvicorn |

### Infrastructure
| Component | Technology |
|---|---|
| Containerization | Docker Compose |
| Reverse Proxy | Nginx |
| Tunnel | Cloudflare Tunnel |

---

## Architecture

The project follows **Feature-First Clean Architecture**:

```
mobile/lib/
├── core/              # Network, router, storage, constants
├── features/
│   ├── auth/          # Login, register, JWT management
│   ├── food_log/      # Daily nutrition tracking
│   ├── activity/      # GPS activity tracking
│   ├── groups/        # Social groups
│   ├── posts/         # Feed, likes, comments
│   └── profile/       # User profile & settings
└── shared/            # Shared widgets (connectivity banner, shimmer)
```

Each feature contains:
- `data/datasources/` — HTTP calls via Dio
- `data/models/` — JSON parsing & domain models
- `presentation/providers/` — Riverpod state
- `presentation/screens/` — UI

---

## Getting Started

### Prerequisites
- Flutter 3.x
- Python 3.12+
- Docker & Docker Compose

### Backend

```bash
cd backend
cp .env.example .env   # fill in your values
docker compose up -d
```

### Mobile

```bash
cd mobile
cp .env.example .env   # set API_BASE_URL
flutter pub get
flutter run
```

---

## Authors

- **Barış Müftüoğlu** — [@bmuftuoglu](https://github.com/bmuftuoglu)

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---
---

> 🇬🇧 English description is above. / İngilizce açıklama yukarıdadır.

---

# MetuFit

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
  <img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img src="https://img.shields.io/badge/Lisans-MIT-green?style=for-the-badge"/>
</p>

Günlük beslenme takibi, GPS aktivite kaydı ve sosyal grup özellikleri sunan tam yığın fitness uygulaması.

---

## Özellikler

- **Beslenme Takibi** — Öğün türüne göre (kahvaltı, öğle, akşam, ara öğün) yiyecek ekle, kalori ve makro besin değerlerini takip et
- **Kalori Panosu** — Tüketilen ve hedef kalorilerini animasyonlu halka grafikle göster, aktivitelerden yakılan kalorileri hesapla
- **Aktivite Takibi** — GPS tabanlı rota kaydı, gerçek zamanlı harita, mesafe, süre ve kalori hesabı
- **Sosyal Gruplar** — Davet koduyla grup oluştur veya katıl, öğün ve aktivite paylaşımı yap, beğen ve yorum yaz
- **Aylık Takvim** — Her güne ait kalori bilgisini gösteren görsel takvim, herhangi bir güne dokunarak o güne git
- **Profil ve Hedefler** — Günlük kalori hedefi, boy, kilo ve yaş bilgilerini ayarla — değişiklikler anında panoya yansır
- **Arka Plan Ön Yükleme** — Son 30 günün verisi uygulama açılışında sessizce yüklenir, gün navigasyonu anında çalışır
- **Bağlantı Uyarısı** — İnternet kesildiğinde bildirim banner'ı
- **JWT Kimlik Doğrulama** — Otomatik token yenileme ile güvenli giriş

---

## Teknoloji Yığını

### Mobil (Flutter)
| Katman | Teknoloji |
|---|---|
| Dil | Dart 3 |
| State Yönetimi | Flutter Riverpod |
| Navigasyon | GoRouter |
| HTTP İstemcisi | Dio + Auth Interceptor |
| Güvenli Depolama | flutter_secure_storage |
| Harita | flutter_map + OpenStreetMap |
| Konum | Geolocator |
| Grafik | fl_chart |
| Yazı Tipi | Google Fonts (Inter) |

### Backend (Python)
| Katman | Teknoloji |
|---|---|
| Framework | FastAPI |
| ORM | SQLAlchemy (async) |
| Veritabanı | PostgreSQL 16 |
| Migrasyon | Alembic |
| Kimlik Doğrulama | JWT (access + refresh token) |
| Dosya Depolama | MinIO |
| Sunucu | Uvicorn |

### Altyapı
| Bileşen | Teknoloji |
|---|---|
| Konteynerizasyon | Docker Compose |
| Ters Proxy | Nginx |
| Tünel | Cloudflare Tunnel |

---

## Mimari

Proje **Feature-First Clean Architecture** yapısını takip eder:

```
mobile/lib/
├── core/              # Ağ, router, depolama, sabitler
├── features/
│   ├── auth/          # Giriş, kayıt, JWT yönetimi
│   ├── food_log/      # Günlük beslenme takibi
│   ├── activity/      # GPS aktivite takibi
│   ├── groups/        # Sosyal gruplar
│   ├── posts/         # Feed, beğeni, yorum
│   └── profile/       # Kullanıcı profili ve ayarlar
└── shared/            # Ortak widget'lar (bağlantı banner'ı, shimmer)
```

Her feature şunları içerir:
- `data/datasources/` — Dio ile HTTP çağrıları
- `data/models/` — JSON parse ve domain modeller
- `presentation/providers/` — Riverpod state
- `presentation/screens/` — UI

---

## Başlarken

### Gereksinimler
- Flutter 3.x
- Python 3.12+
- Docker & Docker Compose

### Backend

```bash
cd backend
cp .env.example .env   # değerleri doldur
docker compose up -d
```

### Mobil

```bash
cd mobile
cp .env.example .env   # API_BASE_URL ayarla
flutter pub get
flutter run
```

---

## Yazarlar

- **Barış Müftüoğlu** — [@bmuftuoglu](https://github.com/bmuftuoglu)

---

## Lisans

Bu proje MIT Lisansı ile lisanslanmıştır. Ayrıntılar için [LICENSE](LICENSE) dosyasına bakın.
