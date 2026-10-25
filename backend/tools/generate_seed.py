#!/usr/bin/env python3
"""Generates src/main/resources/db/seed/R__demo_data.sql (DEVELOPMENT demo catalogue, idempotent)."""
import os

def q(s):
    return "NULL" if s is None else "'" + s.replace("'", "''") + "'"

CATS = [
    ("fruits", "Фрукты", "Жемістер", "Fruits", "fruits"),
    ("vegetables", "Овощи", "Көкөністер", "Vegetables", "vegetables"),
    ("dairy-eggs", "Молочные продукты и яйца", "Сүт өнімдері және жұмыртқа", "Dairy and eggs", "dairy"),
    ("meat-poultry", "Мясо и птица", "Ет және құс еті", "Meat and poultry", "meat"),
    ("fish-seafood", "Рыба и морепродукты", "Балық және теңіз өнімдері", "Fish and seafood", "fish"),
    ("bakery", "Хлеб и выпечка", "Нан және тоқаш", "Bread and bakery", "bakery"),
    ("drinks", "Напитки", "Сусындар", "Drinks", "drinks"),
    ("snacks", "Снеки", "Тіскебасарлар", "Snacks", "snacks"),
    ("frozen", "Замороженные продукты", "Мұздатылған өнімдер", "Frozen foods", "frozen"),
    ("pantry", "Бакалея и крупы", "Бакалея және жарма", "Pantry and grains", "pantry"),
    ("household", "Товары для дома", "Үйге арналған тауарлар", "Household essentials", "household"),
    ("baby", "Детские товары", "Балаларға арналған тауарлар", "Baby products", "baby"),
]

# cat, sku, ru, kk, en, unit, weighted, step_milli, pack_label, price KZT, old price KZT, stock (units), brand, keywords
P = [
 ("fruits","FR-BAN","Бананы","Банан","Bananas","KG",True,500,"1 кг",790,None,120,None,"banana"),
 ("fruits","FR-APL-GAL","Яблоки Гала","Алма Гала","Gala apples","KG",True,500,"1 кг",990,1190,90,None,"apple"),
 ("fruits","FR-ORG","Апельсины","Апельсин","Oranges","KG",True,500,"1 кг",1190,None,80,None,"orange citrus"),
 ("fruits","FR-LEM","Лимоны","Лимон","Lemons","KG",True,250,"1 кг",1490,None,40,None,"lemon citrus"),
 ("fruits","FR-GRP","Виноград белый","Ақ жүзім","White grapes","KG",True,500,"1 кг",2290,2690,35,None,"grape"),
 ("fruits","FR-AVO","Авокадо Хасс","Хасс авокадосы","Hass avocado","PIECE",False,1000,"1 шт",890,None,60,None,"avocado"),
 ("fruits","FR-PER","Груши","Алмұрт","Pears","KG",True,500,"1 кг",1390,None,45,None,"pear"),
 ("fruits","FR-KIW","Киви","Киви","Kiwi","KG",True,250,"1 кг",2490,None,25,None,"kiwi"),
 ("vegetables","VG-TOM-CH","Томаты черри","Черри қызанағы","Cherry tomatoes","PACK",False,1000,"250 г",1190,None,70,None,"tomato cherry"),
 ("vegetables","VG-TOM","Томаты","Қызанақ","Tomatoes","KG",True,500,"1 кг",1290,None,100,None,"tomato"),
 ("vegetables","VG-CUC","Огурцы","Қияр","Cucumbers","KG",True,500,"1 кг",890,None,100,None,"cucumber"),
 ("vegetables","VG-PEP-Y","Перец болгарский жёлтый","Сары болгар бұрышы","Yellow bell pepper","KG",True,250,"1 кг",1990,None,40,None,"pepper bell"),
 ("vegetables","VG-POT","Картофель","Картоп","Potatoes","KG",True,1000,"1 кг",290,None,300,None,"potato"),
 ("vegetables","VG-ONI","Лук репчатый","Пияз","Onions","KG",True,500,"1 кг",190,None,200,None,"onion"),
 ("vegetables","VG-CAR","Морковь","Сәбіз","Carrots","KG",True,500,"1 кг",250,None,200,None,"carrot"),
 ("vegetables","VG-CAB","Капуста белокочанная","Ақ орамжапырақ","White cabbage","KG",True,500,"1 кг",220,None,120,None,"cabbage"),
 ("vegetables","VG-DIL","Укроп","Аскөк","Dill","PACK",False,1000,"пучок",250,None,50,None,"dill herbs greens"),
 ("dairy-eggs","DA-MLK-1","Молоко 3,2%","Сүт 3,2%","Milk 3.2%","L",False,1000,"1 л",590,None,150,"JEMIS Fresh","milk"),
 ("dairy-eggs","DA-KEF","Кефир 2,5%","Кефир 2,5%","Kefir 2.5%","L",False,1000,"1 л",620,None,90,"JEMIS Fresh","kefir"),
 ("dairy-eggs","DA-YOG","Йогурт натуральный","Табиғи йогурт","Natural yogurt","PIECE",False,1000,"350 г",490,None,80,"JEMIS Fresh","yogurt"),
 ("dairy-eggs","DA-CHE","Сыр Гауда","Гауда ірімшігі","Gouda cheese","KG",True,250,"1 кг",5490,6290,25,None,"cheese gouda"),
 ("dairy-eggs","DA-EGG-10","Яйца куриные С1, 10 шт","Тауық жұмыртқасы С1, 10 дана","Chicken eggs, 10 pcs","PACK",False,1000,"10 шт",990,None,120,None,"eggs"),
 ("dairy-eggs","DA-BUT","Масло сливочное 82,5%","Сары май 82,5%","Butter 82.5%","PIECE",False,1000,"180 г",1190,None,60,None,"butter"),
 ("meat-poultry","MT-CHB","Грудка куриная охлаждённая","Салқындатылған тауық төс еті","Chilled chicken breast","KG",True,500,"1 кг",2790,None,40,None,"chicken breast"),
 ("meat-poultry","MT-BEF","Говядина мякоть","Сиыр еті (жұмсағы)","Beef (boneless)","KG",True,500,"1 кг",4990,None,30,None,"beef"),
 ("meat-poultry","MT-LAM","Баранина на кости","Сүйекті қой еті","Lamb on the bone","KG",True,500,"1 кг",4490,None,30,None,"lamb"),
 ("meat-poultry","MT-MIN","Фарш говяжий","Сиыр еті фаршы","Ground beef","KG",True,500,"1 кг",3490,None,25,None,"mince beef"),
 ("fish-seafood","FS-SAL","Филе сёмги охлаждённое","Салқындатылған сёмга филесі","Chilled salmon fillet","KG",True,250,"1 кг",12990,None,15,None,"salmon fish"),
 ("fish-seafood","FS-SHR","Креветки варёно-мороженые","Қайнатылған-мұздатылған асшаян","Cooked frozen shrimp","PACK",False,1000,"500 г",4290,4990,20,None,"shrimp seafood"),
 ("bakery","BK-WHT","Хлеб пшеничный нарезной","Кесілген бидай наны","Sliced wheat bread","PIECE",False,1000,"400 г",290,None,100,None,"bread"),
 ("bakery","BK-BAG","Багет французский","Француз багеті","French baguette","PIECE",False,1000,"250 г",350,None,60,None,"baguette bread"),
 ("bakery","BK-LAV","Лаваш тонкий","Жұқа лаваш","Thin lavash","PACK",False,1000,"3 шт",390,None,70,None,"lavash flatbread"),
 ("bakery","BK-CRO","Круассан","Круассан","Croissant","PIECE",False,1000,"1 шт",450,None,40,None,"croissant pastry"),
 ("drinks","DR-WAT-15","Вода питьевая негазированная 1,5 л","Газсыз ауыз су 1,5 л","Still drinking water 1.5 l","PIECE",False,1000,"1,5 л",190,None,300,None,"water"),
 ("drinks","DR-JUI-OR","Сок апельсиновый 1 л","Апельсин шырыны 1 л","Orange juice 1 l","L",False,1000,"1 л",990,1190,60,None,"juice orange"),
 ("drinks","DR-TEA-BLK","Чай чёрный, 25 пакетиков","Қара шай, 25 пакет","Black tea, 25 bags","PACK",False,1000,"25 пак.",890,None,80,None,"tea"),
 ("drinks","DR-COF-GR","Кофе молотый 250 г","Ұсақталған кофе 250 г","Ground coffee 250 g","PIECE",False,1000,"250 г",2490,None,40,None,"coffee"),
 ("drinks","DR-SOD","Газированный напиток 1 л","Газдалған сусын 1 л","Sparkling soft drink 1 l","L",False,1000,"1 л",490,None,120,None,"soda cola"),
 ("snacks","SN-CHP","Чипсы картофельные","Картоп чипсілері","Potato chips","PIECE",False,1000,"150 г",790,None,90,None,"chips"),
 ("snacks","SN-NUT","Орехи миндаль","Бадам","Almonds","PACK",False,1000,"200 г",1990,None,40,None,"nuts almond"),
 ("snacks","SN-COO","Печенье овсяное","Сұлы печеньесі","Oatmeal cookies","PIECE",False,1000,"300 г",690,None,70,None,"cookies biscuit"),
 ("snacks","SN-CHO","Шоколад молочный","Сүтті шоколад","Milk chocolate","PIECE",False,1000,"90 г",590,None,100,None,"chocolate"),
 ("frozen","FZ-PEL","Пельмени классические","Классикалық тұшпара","Classic dumplings (pelmeni)","PACK",False,1000,"800 г",2190,None,50,None,"pelmeni dumplings"),
 ("frozen","FZ-VEG","Смесь овощная замороженная","Мұздатылған көкөніс қоспасы","Frozen vegetable mix","PACK",False,1000,"400 г",990,None,60,None,"vegetables mix frozen"),
 ("frozen","FZ-ICE","Мороженое пломбир","Пломбир балмұздағы","Ice cream (plombir)","PIECE",False,1000,"450 г",1490,None,40,None,"ice cream"),
 ("pantry","PN-RIC","Рис длиннозёрный","Ұзын дәнді күріш","Long-grain rice","KG",True,500,"1 кг",890,None,150,None,"rice"),
 ("pantry","PN-BUC","Гречневая крупа","Қарақұмық жармасы","Buckwheat groats","KG",True,500,"1 кг",990,None,120,None,"buckwheat"),
 ("pantry","PN-PAS","Макароны спагетти","Спагетти макарон","Spaghetti pasta","PIECE",False,1000,"400 г",490,None,120,None,"pasta spaghetti"),
 ("pantry","PN-OIL","Масло подсолнечное 1 л","Күнбағыс майы 1 л","Sunflower oil 1 l","L",False,1000,"1 л",1290,None,80,None,"oil sunflower"),
 ("pantry","PN-SUG","Сахар-песок","Қант құмы","Granulated sugar","KG",True,1000,"1 кг",490,None,200,None,"sugar"),
 ("pantry","PN-SLT","Соль поваренная","Ас тұзы","Table salt","PIECE",False,1000,"1 кг",150,None,150,None,"salt"),
 ("pantry","PN-FLR","Мука пшеничная","Бидай ұны","Wheat flour","KG",True,1000,"2 кг",790,None,100,None,"flour"),
 ("household","HH-DSH","Средство для мытья посуды","Ыдыс жуу құралы","Dish soap","PIECE",False,1000,"500 мл",690,None,90,None,"dish soap"),
 ("household","HH-PWD","Стиральный порошок","Кір жуу ұнтағы","Laundry powder","PIECE",False,1000,"3 кг",3290,3790,40,None,"laundry detergent"),
 ("household","HH-TPR","Туалетная бумага, 8 рулонов","Дәретхана қағазы, 8 орам","Toilet paper, 8 rolls","PACK",False,1000,"8 рул.",1290,None,80,None,"toilet paper"),
 ("household","HH-BAG","Пакеты для мусора 30 л","Қоқыс пакеттері 30 л","Trash bags 30 l","PACK",False,1000,"30 шт",390,None,100,None,"trash bags"),
 ("baby","BB-PUR","Пюре яблочное детское","Балаларға арналған алма езбесі","Baby apple puree","PIECE",False,1000,"90 г",290,None,100,None,"baby puree apple"),
 ("baby","BB-DIA","Подгузники, размер 4","Жөргектер, 4 өлшем","Diapers, size 4","PACK",False,1000,"50 шт",5990,None,40,None,"diapers"),
 ("baby","BB-WIP","Салфетки влажные детские","Балаларға арналған дымқыл майлықтар","Baby wet wipes","PACK",False,1000,"72 шт",790,None,90,None,"wipes baby"),
]

DESC = {
 "FR-BAN": ("Спелые бананы. Цена указана за 1 кг, итоговая сумма считается по выбранному весу.",
            "Піскен банан. Баға 1 келі үшін көрсетілген, соңғы сома таңдалған салмаққа қарай есептеледі.",
            "Ripe bananas. The price is per 1 kg; the final amount is calculated from the selected weight."),
 "FR-AVO": ("Спелый авокадо сорта Хасс. Продаётся поштучно.", "Хасс сортты піскен авокадо. Данамен сатылады.", "Ripe Hass avocado, sold per piece."),
 "VG-TOM": ("Свежие томаты. Цена за 1 кг.", "Балғын қызанақ. Баға 1 келі үшін.", "Fresh tomatoes. Price per 1 kg."),
 "DA-MLK-1": ("Питьевое молоко жирностью 3,2%.", "Майлылығы 3,2% ауыз сүт.", "Drinking milk, 3.2% fat."),
 "BK-BAG": ("Французский багет, выпекается ежедневно.", "Француз багеті, күн сайын пісіріледі.", "French baguette baked daily."),
}
STORAGE = {
 "DA-MLK-1": ("Хранить при температуре от +2 до +6 °C.", "+2 мен +6 °C аралығында сақтаңыз.", "Store at +2 to +6 °C."),
}

out = ["-- GENERATED by tools/generate_seed.py. DEVELOPMENT DEMO DATA ONLY - loaded only with the 'dev' profile.",
       "-- Names/prices are illustrative. No nutrition, ingredient or allergen facts are invented.", ""]
for i, (slug, ru, kk, en, icon) in enumerate(CATS):
    out.append(f"INSERT INTO categories(slug, name_ru, name_kk, name_en, icon, sort_order) VALUES ({q(slug)},{q(ru)},{q(kk)},{q(en)},{q(icon)},{i}) ON CONFLICT (slug) DO NOTHING;")
out.append("")
for (cat, sku, ru, kk, en, unit, weighted, step, pack, price, old, stock, brand, kw) in P:
    d = DESC.get(sku, (None, None, None))
    s = STORAGE.get(sku, (None, None, None))
    low = 5000 if unit in ("KG", "L") else 10000
    out.append(
        "INSERT INTO products(category_id, sku, brand, name_ru, name_kk, name_en, description_ru, description_kk, description_en, "
        "storage_ru, storage_kk, storage_en, keywords, unit, weighted, step_milli, pack_label, price_minor, old_price_minor, stock_milli, low_stock_milli, popularity) "
        f"SELECT c.id, {q(sku)}, {q(brand)}, {q(ru)}, {q(kk)}, {q(en)}, {q(d[0])}, {q(d[1])}, {q(d[2])}, {q(s[0])}, {q(s[1])}, {q(s[2])}, {q(kw)}, "
        f"{q(unit)}, {'TRUE' if weighted else 'FALSE'}, {step}, {q(pack)}, {price*100}, {'NULL' if old is None else old*100}, {stock*1000}, {low}, {(len(P)-P.index((cat,sku,ru,kk,en,unit,weighted,step,pack,price,old,stock,brand,kw)))} "
        f"FROM categories c WHERE c.slug = {q(cat)} ON CONFLICT (sku) DO NOTHING;")
out += [
 "",
 "INSERT INTO promotions(code, type, value, max_discount_minor, min_order_minor, per_customer_limit) VALUES ('WELCOME10','PERCENT',10,100000,500000,1) ON CONFLICT (code) DO NOTHING;",
 "INSERT INTO promotions(code, type, value, min_order_minor) VALUES ('FRESH500','FIXED',50000,300000) ON CONFLICT (code) DO NOTHING;",
 "",
 "INSERT INTO banners(title_ru,title_kk,title_en,subtitle_ru,subtitle_kk,subtitle_en,color,sort_order) SELECT 'Свежесть у твоей двери','Күн сайын балғындық','Freshness at Your Door','Доставка продуктов по Алматы','Алматы бойынша азық-түлік жеткізу','Grocery delivery in Almaty','#27883F',1 WHERE NOT EXISTS (SELECT 1 FROM banners WHERE title_en='Freshness at Your Door');",
 "INSERT INTO banners(title_ru,title_kk,title_en,subtitle_ru,subtitle_kk,subtitle_en,color,sort_order) SELECT 'Скидка 10% на первый заказ','Алғашқы тапсырысқа 10% жеңілдік','10% off your first order','Промокод WELCOME10 от 5 000 ₸','WELCOME10 промокоды 5 000 ₸-ден','Promo code WELCOME10 from 5,000 ₸','#174A2A',2 WHERE NOT EXISTS (SELECT 1 FROM banners WHERE title_en='10% off your first order');",
 "INSERT INTO banners(title_ru,title_kk,title_en,subtitle_ru,subtitle_kk,subtitle_en,color,sort_order) SELECT 'Сезонные фрукты и овощи','Маусымдық жеміс-жидек','Seasonal fruit and vegetables','Выбирайте свежее','Балғынын таңдаңыз','Pick the freshest','#C7A700',3 WHERE NOT EXISTS (SELECT 1 FROM banners WHERE title_en='Seasonal fruit and vegetables');",
 "",
 "INSERT INTO delivery_zones(name, city, fee_minor, min_order_minor, free_delivery_threshold_minor) SELECT 'Алматы','Алматы',99000,300000,1500000 WHERE NOT EXISTS (SELECT 1 FROM delivery_zones WHERE city='Алматы');",
 "INSERT INTO delivery_slot_templates(start_time,end_time,capacity) SELECT t.s::time, t.e::time, 10 FROM (VALUES ('10:00','12:00'),('12:00','14:00'),('14:00','16:00'),('16:00','18:00'),('18:00','20:00'),('20:00','22:00')) AS t(s,e) WHERE NOT EXISTS (SELECT 1 FROM delivery_slot_templates);",
]
path = os.path.join(os.path.dirname(__file__), "..", "src", "main", "resources", "db", "seed", "R__demo_data.sql")
open(path, "w").write("\n".join(out) + "\n")
print("products:", len(P), "categories:", len(CATS))
