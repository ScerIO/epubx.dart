import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:html/parser.dart';

Future main() async {
  print(1);
  var bytes = await File('test-book.epub').readAsBytes();
 // final byteData = await rootBundle.load(assetName);
//  final bytes = byteData.buffer.asUint8List();
  return EpubReader.readBook(bytes);

 /* final doc = parse(htmlTest);
 final item =  doc.getElementById("uGqeclf8MxKocbEYtWPCXu5");
  htmlTest.indexOf(item!.outerHtml);
 final allitems = doc.querySelectorAll("*");
 print(1); */
}

const htmlTest = """   <h3 class="Rozdil№">
        <a></a>
      </h3>
      <h3 id="uGqeclf8MxKocbEYtWPCXu5" class="Rozdil_nazwa _idGenParaOverride-1">
        <a id="uNdHCvOBdfzfpKhWeyfBbJB"></a>Фото
      </h3>
      <div class="_idGenObjectLayout-1">
        <div id="uNIKjYhiFatbb69FGUIddU6">
          <img class="_idGenObjectAttribute-1" src="image/1-1.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">Родина Фостерів, 1920-ті роки. Зліва направо: Джеймс (мій батько), Джон (дядько Білл), Марія (моя бабуся), Джо (мій дідусь)</p>
      <div class="_idGenObjectLayout-1">
        <div id="uTabRRXnjx42IJajGb3NytE">
          <img class="_idGenObjectAttribute-1" src="image/1.2.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">J. W. Foster &amp; Sons, Олімпійська майстерня, Дін-роуд, Болтон. У будинку № 57 (ліворуч) була перша майстерня, а згодом Джо викупив сусідній паб Horse and Vulcan у будинку № 59</p>
      <div class="_idGenObjectLayout-1">
        <div id="uzNfxjmaVZoRPZGFbyslwG8">
          <img class="_idGenObjectAttribute-1" src="image/1-3.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">Усередині Олімпійської майстерні: Білл (ліворуч скраю), Джим (ліворуч), Джо (праворуч скраю)</p>
      <div class="_idGenObjectLayout-1">
        <div id="uRpcaf4DcqCjMoni8MbKOp4">
          <img class="_idGenObjectAttribute-1" src="image/2-1.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Неллі Голстед, одна з найкращих спортсменок в історії Британії, яка побила кілька рекордів у взутті від Foster’s</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="uzzekvVoJe57TytdciHSN76">
          <img class="_idGenObjectAttribute-1" src="image/2-2.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Рекламна листівка (високий друк) бігових кросівок ручної роботи DeLuxe від Foster’s</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="upUCiptb7YcAKwXC4pJURh5">
          <img class="_idGenObjectAttribute-1" src="image/2.3.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Сіріл Голмс з «Болтон Юнайтед Гарріерс» виступив на Олімпійських іграх у Берліні 1936 року від Британії у взутті від дядька Білла — такому тісному, що взути його можна було лише один раз</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="ukCLfjf2cbwJRIpthzrY3v5">
          <img class="_idGenObjectAttribute-1" src="image/2.4.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">У 1904 році на стадіоні «Айброкс» Альфред Шрабб побив три світові рекорди у взутті від Foster’s</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="uEWIf7m6Te2zRGY6s42MZwD">
          <img class="_idGenObjectAttribute-1" src="image/3.1.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Восьмирічний я з кубками і срібною (чи золотою) медаллю на грудях</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="uhMNR65392zUcgBMdLTypd5">
          <img class="_idGenObjectAttribute-1" src="image/3.2.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Наші скаутські дні. Джефф (у задньому ряду в центрі) і я (в центрі)</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="uqOm6q3fmAASCSkqT7oj4i4">
          <img class="_idGenObjectAttribute-1" src="image/3.3.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">Ми з Джеффом (праворуч) вирушаємо на скаутський захід. Нас проводжають Бессі (наша матір) і Джон (молодший брат). Фотографував наш батько Джеймс</p>
      <div class="_idGenObjectLayout-1">
        <div id="u8U3oYLOZYzZO8FLKz5pEz8">
          <img class="_idGenObjectAttribute-1" src="image/4-1.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">Усередині фабрики на Брайт-стріт у Бері. Тревор працює на пресі для кріплення підошов</p>
      <div class="_idGenObjectLayout-1">
        <div id="uIyy45YK7XutJl6lm8XVvT4">
          <img class="_idGenObjectAttribute-1" src="image/4-2.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Свідоцтво про реєстрацію торгової марки Reebok. Логотип у центрі (факел або ріжок для морозива) — візерунок на боці нашого взуття</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="us6KgWEgxUROTml26mdRTgC">
          <img class="_idGenObjectAttribute-1" src="image/4-3_4-4.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Упізнаю почерк, але не малюнки. До речі, з часом мої художні навички поліпшилися</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="uPdRbLuk5h9vpGCuQhfXmG9">
          <img class="_idGenObjectAttribute-1" src="image/5-1.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Реклама «Нове золото». У 1979 році модель Aztec отримала п’ять зірок у Runner’s World і стала нашим головним проривом у США</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="uTkJNL98eSkZLDzNtUgx2b3">
          <img class="_idGenObjectAttribute-1" src="image/5-2.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Перша класична версія американської реклами моделі для аеробіки Freestyle</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="ueIg4ZQwZRVUU9Uzt846Vw4">
          <img class="_idGenObjectAttribute-1" src="image/5-3.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Одна з перших успішних моделей — Ripple. Тут є колишній логотип і оригінальна бічна смуга</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="useXXpivz5xJP9pBaTbvew8">
          <img class="_idGenObjectAttribute-1" src="image/6-1.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">Світовий успіх Reebok: Сібілл Шеперд взула наші кросівки з високим верхом на церемонію вручення «Еммі» в 1985 році <br />
        <span class="Plate-source _idGenCharOverride-3">© Getty Images</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="uhqFGJMKQmTp6uWo79NmgK7">
          <img class="_idGenObjectAttribute-1" src="image/6-2.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys">
        <span class="CharOverride-3" lang="en-US" xml:lang="en-US">Типовий урок аеробіки. Усі у взутті від Reebok</span>
      </p>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span class="Plate-source _idGenCharOverride-3">© Getty Images</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="uWD7qxIkz6kzHKYQSqFBvP2">
          <img class="_idGenObjectAttribute-1" src="image/6-3.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Акторський склад фільму «Чужі». Сіґурні Вівер полює за поганими інопланетянами в парі футуристичних кросівок Alien Stompers від Reebok</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="u3vOrWegqJ9vDZOzqEb54M2">
          <img class="_idGenObjectAttribute-1" src="image/7-1.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">Я (праворуч) з Полом Файрманом. Пол приїхав у Болтон, щоб подивитися, як рухається будівництво нової міжнародної штаб-квартири, й разом закопати капсулу часу</p>
      <div class="_idGenObjectLayout-1">
        <div id="uIh2HxWarR6WMyN6e39OT2A">
          <img class="_idGenObjectAttribute-1" src="image/7.2.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys">
        <span lang="en-US" xml:lang="en-US">Чарлтон Гестон і Венделл Найлз на відкритті Reebok House у Болтоні в 1988 році</span>
      </p>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span class="Plate-source CharOverride-4" lang="en-US" xml:lang="en-US">© Getty Images</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="u2gfugjoiFnzrngE49cLYrE">
          <img class="_idGenObjectAttribute-1" src="image/7.3.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">У Монте-Карло до нас приєдналося багато зірок, зокрема Шерон Стоун</p>
      <div class="_idGenObjectLayout-1">
        <div id="umlgaLzrmwQMMqEdTak7ADA">
          <img class="_idGenObjectAttribute-1" src="image/8.1.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Вручення Трофея імені принцеси Ґрейс переможцям зіркового тенісного турніру</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="upMMDf2WsyQQsunty7hRjy8">
          <img class="_idGenObjectAttribute-1" src="image/8.2.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">Я зі знаменитостями зіркового тенісного турніру в Монте-Карло у класичних тенісних футболках з дизайном від Туана Ле</p>
      <div class="_idGenObjectLayout-1">
        <div id="uzLcXIcYKz5ebbcj4iPPfI5">
          <img class="_idGenObjectAttribute-1" src="image/8-3.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">
        <span lang="en-US" xml:lang="en-US">Я на тлі гавані Сіднея під час візиту до сім’ї Гендлер, яку призначив дистриб’ютором Reebok в Австралії та Новій Зеландії</span>
      </p>
      <div class="_idGenObjectLayout-1">
        <div id="uHykGlPMgqX8J5nalWMMKV8">
          <img class="_idGenObjectAttribute-1" src="image/8.4.jpg" alt="" />
        </div>
      </div>
      <p class="mal-unok-pidpys _idGenParaOverride-1">Моя донька Кей з Дольфом Лундґреном (Хі-Меном) на  «Зірковій ночі в Болтоні», яку компанія Reebok влаштувала в 1988 році. <a id="uKupMjRPgSfqvFkU2jojeu7"></a>
      </p>""";
