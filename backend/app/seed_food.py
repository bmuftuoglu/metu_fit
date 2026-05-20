"""
Run: docker exec backend-api-1 python seed_food.py
"""
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from src.config import settings
from src.models.food import FoodItem

FOODS = [
    # name, brand, cal/100g, protein, carbs, fat
    ("Yulaf Ezmesi", None, 389, 16.9, 66.3, 6.9),
    ("Tavuk Göğsü (Izgara)", None, 165, 31.0, 0.0, 3.6),
    ("Yumurta", None, 155, 13.0, 1.1, 11.0),
    ("Süt (%3.5)", None, 61, 3.2, 4.8, 3.5),
    ("Yoğurt (Tam Yağlı)", None, 61, 3.5, 4.7, 3.3),
    ("Beyaz Peynir", None, 264, 17.5, 2.4, 20.5),
    ("Kaşar Peyniri", None, 406, 27.8, 1.3, 32.5),
    ("Ekmek (Tam Buğday)", None, 247, 9.7, 41.2, 4.2),
    ("Pirinç (Pişmiş)", None, 130, 2.7, 28.2, 0.3),
    ("Makarna (Pişmiş)", None, 158, 5.8, 30.9, 0.9),
    ("Patates (Haşlanmış)", None, 87, 1.9, 20.1, 0.1),
    ("Tatlı Patates", None, 86, 1.6, 20.1, 0.1),
    ("Domates", None, 18, 0.9, 3.9, 0.2),
    ("Salatalık", None, 15, 0.7, 3.6, 0.1),
    ("Biber (Kırmızı)", None, 31, 1.0, 6.0, 0.3),
    ("Ispanak", None, 23, 2.9, 3.6, 0.4),
    ("Marul", None, 15, 1.4, 2.9, 0.2),
    ("Brokoli", None, 34, 2.8, 6.6, 0.4),
    ("Havuç", None, 41, 0.9, 9.6, 0.2),
    ("Soğan", None, 40, 1.1, 9.3, 0.1),
    ("Sarımsak", None, 149, 6.4, 33.1, 0.5),
    ("Elma", None, 52, 0.3, 13.8, 0.2),
    ("Muz", None, 89, 1.1, 22.8, 0.3),
    ("Portakal", None, 47, 0.9, 11.8, 0.1),
    ("Çilek", None, 32, 0.7, 7.7, 0.3),
    ("Karpuz", None, 30, 0.6, 7.6, 0.2),
    ("Üzüm", None, 69, 0.7, 18.1, 0.2),
    ("Kivi", None, 61, 1.1, 14.7, 0.5),
    ("Avokado", None, 160, 2.0, 8.5, 14.7),
    ("Badem", None, 579, 21.2, 21.6, 49.9),
    ("Ceviz", None, 654, 15.2, 13.7, 65.2),
    ("Fıstık Ezmesi", None, 588, 25.1, 19.6, 50.4),
    ("Zeytinyağı", None, 884, 0.0, 0.0, 100.0),
    ("Tereyağı", None, 717, 0.9, 0.1, 81.1),
    ("Somon (Izgara)", None, 208, 28.0, 0.0, 10.1),
    ("Ton Balığı (Konserve)", None, 116, 25.5, 0.0, 0.8),
    ("Dana Kıyma (%15 Yağ)", None, 215, 26.1, 0.0, 11.8),
    ("Tavuk But (Derili)", None, 235, 18.4, 0.0, 17.4),
    ("Hindi Göğsü", None, 135, 29.9, 0.0, 1.0),
    ("Sosis (Dana)", None, 301, 13.3, 2.7, 26.1),
    ("Mercimek (Pişmiş)", None, 116, 9.0, 20.1, 0.4),
    ("Nohut (Pişmiş)", None, 164, 8.9, 27.4, 2.6),
    ("Fasulye (Pişmiş)", None, 127, 8.7, 22.8, 0.5),
    ("Kinoa (Pişmiş)", None, 120, 4.4, 21.3, 1.9),
    ("Çikolata (Sütlü)", "Ülker", 535, 7.7, 59.4, 29.7),
    ("Çikolata (Bitter 70%)", None, 598, 7.8, 45.9, 42.6),
    ("Dondurma (Vanilyalı)", None, 207, 3.5, 23.6, 11.0),
    ("Cola", "Coca-Cola", 42, 0.0, 10.6, 0.0),
    ("Portakal Suyu", None, 45, 0.7, 10.4, 0.2),
    ("Çay (Şekersiz)", None, 1, 0.0, 0.3, 0.0),
    ("Kahve (Sade)", None, 2, 0.3, 0.0, 0.0),
    ("Protein Tozu (Whey)", None, 370, 80.0, 7.0, 5.0),
    ("Energy Bar", None, 390, 10.0, 55.0, 14.0),
    ("Granola", None, 471, 10.4, 65.4, 19.6),
    ("Bal", None, 304, 0.3, 82.4, 0.0),
    ("Reçel", None, 278, 0.4, 68.9, 0.1),
    ("Kraker", None, 455, 10.0, 67.3, 16.1),
    ("Cips (Patates)", None, 536, 7.0, 53.0, 34.0),
    ("Pizza (Margherita)", None, 266, 11.4, 32.9, 10.0),
    ("Hamburger (Ekmeksiz)", None, 295, 17.0, 6.0, 22.0),
    ("Döner Kebap", None, 248, 19.3, 3.2, 17.9),
    ("Köfte (Izgara)", None, 231, 25.8, 2.1, 13.2),
    ("Pilav (Tereyağlı)", None, 153, 3.0, 31.0, 2.5),
    ("Mercimek Çorbası", None, 63, 4.0, 9.0, 1.0),
    ("Ayran", None, 40, 2.8, 3.8, 1.5),
    ("Kefir", None, 41, 3.3, 4.8, 1.0),
    ("Lor Peyniri", None, 98, 11.1, 3.3, 4.5),
    ("Süzme Yoğurt", None, 97, 9.9, 3.6, 4.8),
    ("Müsli (Şekersiz)", None, 370, 10.5, 56.3, 9.7),
    ("Tavuk Shawarma", None, 229, 24.0, 5.0, 12.0),
    ("Falafel", None, 333, 13.3, 31.8, 17.8),
    ("Humus", None, 166, 7.9, 14.3, 9.6),
    ("Tahin", None, 595, 17.0, 26.2, 53.8),
    ("Zeytin (Yeşil)", None, 115, 0.8, 6.3, 10.7),
    ("Soya Sütü", None, 33, 3.3, 1.8, 1.8),
    ("Baklava", None, 428, 8.1, 41.3, 26.3),
    ("Sütlaç", None, 124, 4.1, 20.3, 3.1),
    ("Kadayıf", None, 285, 5.2, 37.0, 13.5),
    ("Helva (Tahin)", None, 516, 12.1, 55.3, 29.0),
    ("Lokum", None, 350, 0.0, 87.5, 0.0),
    ("Poğaça (Sade)", None, 338, 9.2, 43.5, 14.1),
    ("Simit", None, 287, 9.1, 53.8, 4.6),
    ("Börek (Peynirli)", None, 290, 12.0, 27.0, 15.0),
    ("Gözleme (Peynirli)", None, 237, 9.0, 28.0, 10.0),
    ("Tarhana Çorbası", None, 54, 3.2, 8.6, 0.7),
    ("Ezogelin Çorbası", None, 68, 4.5, 10.1, 0.9),
]


async def seed():
    engine = create_async_engine(
        settings.database_url.replace("postgresql://", "postgresql+asyncpg://"),
        echo=False,
    )
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        from sqlalchemy import select
        existing = await session.execute(select(FoodItem).limit(1))
        if existing.scalar_one_or_none():
            print("Seed data already exists, skipping.")
            return

        items = [
            FoodItem(
                name=name,
                brand=brand,
                calories_per_100g=cal,
                protein_g=protein,
                carbs_g=carbs,
                fat_g=fat,
                is_custom=False,
            )
            for name, brand, cal, protein, carbs, fat in FOODS
        ]
        session.add_all(items)
        await session.commit()
        print(f"Seeded {len(items)} food items.")


if __name__ == "__main__":
    asyncio.run(seed())
