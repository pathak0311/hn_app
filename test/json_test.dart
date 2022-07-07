import 'package:flutter_test/flutter_test.dart';
import 'package:hn_app/src/article.dart';
import 'package:http/http.dart';

void main() {
  test("parses topstories.json", () {
    const jsonString =
        "[31963460,31964766,31944705,31963813,31964685,31964867,31959890,31945504,31945863,31960219,31959289,31944198,31952610,31960814,31944043,31963070,31945478,31944555,31944680,31962355,31943639,31960962,31962014,31962745,31961912,31961216,31943528,31961239,31958823,31950974,31954518,31961402,31954225,31964415,31961244,31958536,31941694,31957554,31960204,31957551,31957908,31963065,31957255,31960348,31962377,31949731,31961480,31959800,31958597,31943683,31957603,31955970,31961992,31963433,31952128,31957004,31963295,31957210,31960676,31963883,31952643,31948661,31963597,31959666,31957068,31958331,31944278,31943131,31958201,31946390,31949621,31961691,31955334,31941902,31942329,31947297,31962313,31961502,31962699,31961389,31963663,31960688,31958603,31961508,31941873,31956195,31954053,31963839,31940771,31945489,31958594,31963140,31960322,31945564,31943420,31963077,31941480,31938639,31956947,31957477,31963629,31938261,31960250,31943198,31956069,31956626,31949348,31954711,31961006,31943531,31956318,31949535,31953662,31951308,31961066,31957118,31961886,31943770,31961637,31954133,31958945,31959730,31939871,31964358,31956308,31941777,31945994,31957863,31952379,31954745,31963224,31942835,31940277,31941472,31953470,31960517,31955338,31941138,31960393,31932423,31961038,31956861,31963479,31963478,31952184,31944575,31961173,31941089,31963329,31947295,31947066,31948881,31928999,31955647,31959220,31963184,31960758,31930718,31945841,31962404,31930935,31945618,31959719,31929346,31948168,31943572,31941607,31930551,31961622,31956944,31926813,31962129,31957538,31960953,31960631,31927658,31927043,31963605,31954938,31959141,31954294,31950287,31947291,31941887,31952678,31959859,31954468,31953682,31930086,31962644,31961110,31940567,31953312,31934181,31939983,31940030,31948958,31942933,31952579,31946039,31950097,31926594,31947895,31938609,31958738,31950899,31944636,31945161,31929140,31937133,31953880,31945425,31938353,31960723,31930537,31957648,31936725,31962558,31940321,31944446,31940801,31955418,31955627,31957311,31957136,31932349,31941264,31950264,31929662,31948849,31931042,31952132,31956773,31955946,31936356,31954845,31928608,31959929,31929700,31944497,31929897,31957321,31956655,31961387,31939013,31935626,31963944,31927902,31958022,31942598,31943199,31941326,31961154,31944287,31947799,31957133,31927669,31932202,31958969,31930384,31950723,31938350,31959873,31929220,31945924,31954492,31955842,31953300,31945607,31938761,31945787,31936300,31957880,31945855,31946528,31929941,31934400,31934963,31932434,31947474,31954611,31935630,31935093,31926142,31955105,31928307,31960692,31960502,31928736,31956716,31954528,31932808,31944209,31939424,31951348,31930008,31958748,31930896,31931887,31928826,31948833,31955198,31944760,31939300,31932085,31953171,31949985,31929451,31953752,31929005,31961225,31947539,31932250,31947296,31959285,31927512,31959269,31956162,31959086,31939114,31939130,31955123,31930460,31953505,31950573,31935116,31943880,31956950,31935425,31955471,31939339,31932302,31936015,31944616,31927423,31931727,31957427,31950495,31938789,31951068,31928676,31961910,31948172,31951132,31958326,31927930,31945378,31933829,31946088,31940160,31953652,31928739,31926218,31943456,31939265,31949049,31956870,31942284,31950526,31957842,31953713,31962345,31957690,31942980,31958715,31950790,31944539,31959638,31952025,31956565,31950430,31946227,31948139,31942934,31940135,31930789,31950969,31929717,31945971,31943986,31937401,31958362,31941781,31941728,31949639,31956969,31958523,31951653,31938246,31939177,31954401,31958998,31945583,31929248,31949610,31927584,31949485,31945525,31952799,31935844,31941295,31933849,31952426,31941238,31935989,31941040,31947172,31956462,31938540,31960238,31954916,31947567,31954667,31954537,31940115,31954165,31932917,31930706,31953983,31938834,31930328,31938689,31929102,31962392,31949723,31936306,31937457,31953289,31926342,31930688,31958232,31929058,31939889,31930011,31936063,31929973,31936110,31935499,31951625,31960110,31942099,31933995,31951422,31954982,31954968,31938452,31933860,31932460,31941231,31950238,31959347,31954565,31943596,31926250,31926186,31954179,31928687,31949222,31946145,31954040,31954004,31928266,31935121,31941670,31953849,31937612,31930547,31930144,31953602,31930092,31933529,31953434,31953431,31953206,31947179,31944777,31951683,31952780,31940402,31934895,31952639,31952631,31937711,31946448,31944458,31933497,31951891,31945732,31951676,31951665,31935541,31926681,31951931,31926380,31941009,31950817,31950548,31933113,31955479,31937333]";

    expect(parseTopStories(jsonString).first, 31963460);
  });

  test("parses item.json", () {
    const jsonString =
        """{"by":"dhouston","descendants":71,"id":8863,"kids":[9224,8917,8952,8958,8884,8887,8869,8873,8940,8908,9005,9671,9067,9055,8865,8881,8872,8955,10403,8903,8928,9125,8998,8901,8902,8907,8894,8870,8878,8980,8934,8943,8876],"score":104,"time":1175714200,"title":"My YC app: Dropbox - Throw away your USB drive","type":"story","url":"http://www.getdropbox.com/u/2/screencast.html"}""";

    expect(parseArticle(jsonString).by, "dhouston");
  });

  test("parses item.json over a network", () async {
    const url = "https://hacker-news.firebaseio.com/v0/beststories.json";

    final res = await get(Uri.parse(url));

    if(res.statusCode == 200){
      final idList = parseTopStories(res.body);

      if(idList.isNotEmpty){
        final storyUrl = "https://hacker-news.firebaseio.com/v0/item/${idList.first}.json";
        final storyRes = await get(Uri.parse(storyUrl));
        if(storyRes.statusCode == 200){
          expect(parseArticle(storyRes.body), isNotNull);
        }
      }
    }
  }, skip: true);
}
