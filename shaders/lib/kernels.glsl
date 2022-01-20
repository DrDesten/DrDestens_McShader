

//////////////////////////////////////////////////////
//              BLUR KERNELS
//////////////////////////////////////////////////////


const vec2 vogel_disk_4[4] = vec2[](
    vec2(0.21848650099008202, -0.09211370200809937),
    vec2(-0.5866112654782878, 0.32153793477769893),
    vec2(-0.06595078555407359, -0.879656059066481),
    vec2(0.43407555004227927, 0.6502318262968816)
);

const vec2 vogel_disk_8[8] = vec2[](
    vec2(0.2921473492144121, 0.03798942536906266),
    vec2(-0.27714274097351554, 0.3304853027892154),
    vec2(0.09101981507673855, -0.5188871157785563),
    vec2(0.44459182774878003, 0.5629069824170247),
    vec2(-0.6963877647721594, -0.09264703741542105),
    vec2(0.7417522811565185, -0.4070419658858473),
    vec2(-0.191856808948964, 0.9084732299066597),
    vec2(-0.40412395850181015, -0.8212788214021378)
);

const vec2 vogel_disk_16[16] = vec2[](
    vec2(0.18993645671348536, 0.027087114076591513),
    vec2(-0.21261242652069953, 0.23391293246949066),
    vec2(0.04771781344140756, -0.3666840644525993),
    vec2(0.297730981239584, 0.398259878229082),
    vec2(-0.509063425827436, -0.06528681462854097),
    vec2(0.507855152944665, -0.2875976005206389),
    vec2(-0.15230616564632418, 0.6426121151781916),
    vec2(-0.30240170651828074, -0.5805072900736001),
    vec2(0.6978019230005561, 0.2771173334141519),
    vec2(-0.6990963248129052, 0.3210960724922725),
    vec2(0.3565142601623699, -0.7066415061851589),
    vec2(0.266890002328106, 0.8360191043249159),
    vec2(-0.7515861305520581, -0.41609876195815027),
    vec2(0.9102937449894895, -0.17014527555321657),
    vec2(-0.5343471434373126, 0.8058593459499529),
    vec2(-0.1133270115046468, -0.9490025827627441)
);

const vec2 vogel_disk_32[32] = vec2[](
    vec2(0.12064426510477419, 0.01555443141176569),
    vec2(-0.16400077998918963, 0.16180237012184204),
    vec2(0.020080498035937415, -0.2628838391620438),
    vec2(0.19686650437195816, 0.27801320993574674),
    vec2(-0.37362329188851157, -0.04976379998047616),
    vec2(0.34544673107582735, -0.20696126421568928),
    vec2(-0.12135781397691386, 0.4507963336805642),
    vec2(-0.22749138875333694, -0.41407969197383454),
    vec2(0.4797593802468298, 0.19235249500691445),
    vec2(-0.5079968434096749, 0.22345015963708734),
    vec2(0.23843255951864029, -0.5032700515259672),
    vec2(0.17505863904522073, 0.587555727235086),
    vec2(-0.5451127409909945, -0.29782530685850084),
    vec2(0.6300137885218894, -0.12390992876509888),
    vec2(-0.391501580064061, 0.5662295575692019),
    vec2(-0.09379538975841809, -0.6746452122696498),
    vec2(0.5447160222309757, 0.47831268960533435),
    vec2(-0.7432342062047558, 0.046109375942755174),
    vec2(0.5345993903170301, -0.520777903066999),
    vec2(-0.0404139208253129, 0.7953459466435174),
    vec2(-0.517173266802963, -0.5989723613060595),
    vec2(0.8080038585189984, 0.12485626574164434),
    vec2(-0.6926663754026566, 0.4944630470831171),
    vec2(0.183730322451809, -0.8205069509230769),
    vec2(0.43067753069940745, 0.7747454863024757),
    vec2(-0.8548041452377114, -0.25576180722119723),
    vec2(0.8217466662308877, -0.3661258311820314),
    vec2(-0.36224393661662146, 0.87070999332353),
    vec2(-0.32376306917956177, -0.8724793262829371),
    vec2(0.8455529005007657, 0.46224259051084376),
    vec2(-0.9483903811252437, 0.2643989345002705),
    vec2(0.5322400733549763, -0.818975339518135)
);

const vec2 vogel_disk_64[64] = vec2[](
    vec2(0.07966914016126773, -0.0005732549414365655),
    vec2(-0.12160530145582471, 0.10283965425501301),
    vec2(0.008559818525228833, -0.197458844206032),
    vec2(0.13356640242431705, 0.18501312713480866),
    vec2(-0.269830801109193, -0.04676021929400281),
    vec2(0.23862848827685754, -0.15791561224005177),
    vec2(-0.09145217101863704, 0.3071892456093635),
    vec2(-0.16649994145461533, -0.30437045701653237),
    vec2(0.33360187330480306, 0.12444185472734362),
    vec2(-0.3648472506019276, 0.14643122426640393),
    vec2(0.16295804188571, -0.36743756507231173),
    vec2(0.11814591296857804, 0.40389274018272564),
    vec2(-0.39109215347150406, -0.22216619295880746),
    vec2(0.43984778429926974, -0.0991894497563406),
    vec2(-0.2824726599141313, 0.38881286099524415),
    vec2(-0.07196259394779835, -0.48861810336110434),
    vec2(0.3795331553348995, 0.3266462474773111),
    vec2(-0.5311851850227693, 0.021032353535204915),
    vec2(0.3723796163057802, -0.3798174856209827),
    vec2(-0.03421619527550065, 0.5508226133906681),
    vec2(-0.37133596181036055, -0.43510931729303065),
    vec2(0.5657057697780938, 0.07671481330934922),
    vec2(-0.49542832895271105, 0.3380662747684381),
    vec2(0.12427771910967947, -0.5917579278786026),
    vec2(0.2988957646566429, 0.536255888187953),
    vec2(-0.6100770454895419, -0.19242280712483223),
    vec2(0.5754234023037136, -0.27046195686657265),
    vec2(-0.2617843818309086, 0.6041130418557645),
    vec2(-0.2345742995202231, -0.6285079469299325),
    vec2(0.59225695199046, 0.315282971433257),
    vec2(-0.6762525075113398, 0.17538638065344198),
    vec2(0.37071132728294354, -0.5906749150680255),
    vec2(0.1119798859418661, 0.7017402283731283),
    vec2(-0.5807270152810202, -0.4435682524557845),
    vec2(0.7229827225912143, -0.06119326417718071),
    vec2(-0.5144794788954391, 0.5461387788248903),
    vec2(-0.005035179534685496, -0.7557546423829214),
    vec2(0.5055857377426614, 0.5663728829872585),
    vec2(-0.7810140733390272, -0.07214936952359105),
    vec2(0.6170681003447506, -0.47552351060683423),
    vec2(-0.15109977600025168, 0.7820762666899624),
    vec2(-0.43760314844428994, -0.6821127366950525),
    vec2(0.7772009255491943, 0.21481487028437787),
    vec2(-0.742204728724318, 0.3758394044302885),
    vec2(0.28114246867378123, -0.7824253564882913),
    vec2(0.3091922614465049, 0.7803683548608),
    vec2(-0.7789831306606205, -0.36561570268862775),
    vec2(0.8145440939773348, -0.2543941296975529),
    vec2(-0.4488757377357506, 0.7504758305912105),
    vec2(-0.1933624476019976, -0.8604246222601459),
    vec2(0.7154581485450054, 0.513848417434855),
    vec2(-0.8988765686147268, 0.11036534262592021),
    vec2(0.5783350546530844, -0.6902686901177914),
    vec2(0.024600692161986272, 0.9131155784626814),
    vec2(-0.6564461645240189, -0.657849672537283),
    vec2(0.9212949234450745, 0.04697899281368057),
    vec2(-0.7330423210662792, 0.5978985715758123),
    vec2(0.12225611512756368, -0.9393399804201348),
    vec2(0.5334856827883492, 0.7868760176859763),
    vec2(-0.948368229388031, -0.21678429915641398),
    vec2(0.8372175428305082, -0.4798472000523386),
    vec2(-0.31121110469716806, 0.9318623471900049),
    vec2(-0.41881630178513873, -0.899674402337137),
    vec2(0.9082566602526256, 0.38845471061254216)
);

vec2 starOffsets[4] = vec2[4](
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0,  0.0),
	vec2( 0.0, -1.0)
);

const float gaussian_3[3] = float[](
    0.25,
    0.5,
    0.25
);

const float gaussian_4[4] = float[](
    0.125,
    0.375,
    0.375,
    0.125
);

const float gaussian_5[5] = float[](
    0.0625,
    0.25,
    0.375,
    0.25,
    0.0625
);

const float gaussian_6[6] = float[](
    0.03125,
    0.15625,
    0.3125,
    0.3125,
    0.15625,
    0.03125
);

const float gaussian_10[10] = float[](
    0.001953125,
    0.017578125,
    0.0703125,
    0.1640625,
    0.24609375,
    0.24609375,
    0.1640625,
    0.0703125,
    0.017578125,
    0.001953125
);

const float gaussian_16[16] = float[](
    0.000030517578125,
    0.000457763671875,
    0.003204345703125,
    0.013885498046875,
    0.041656494140625,
    0.091644287109375,
    0.152740478515625,
    0.196380615234375,
    0.196380615234375,
    0.152740478515625,
    0.091644287109375,
    0.041656494140625,
    0.013885498046875,
    0.003204345703125,
    0.000457763671875,
    0.000030517578125
);


//////////////////////////////////////////////////////
//              SSAO KERNELS
//////////////////////////////////////////////////////

const vec3 half_sphere_8[8] = vec3[](
    vec3(0.4841229182759271, 0, 0.875),
    vec3(-0.5756083959600474, 0.5273044419500952, 0.625),
    vec3(0.08104581592239497, -0.923475270768781, 0.375),
    vec3(0.603666717801552, 0.7873763355719433, 0.12500000000000006),
    vec3(-0.9769901230486042, -0.17281579634244423, 0.12499999999999994),
    vec3(0.7821820926083319, -0.497560221483642, 0.375),
    vec3(-0.20265354556067547, 0.7538610883124871, 0.6249999999999999),
    vec3(-0.22313565385811115, -0.42963412338560025, 0.875)
);

const vec3 half_sphere_16[16] = vec3[](
    vec3(0.34798527267687634, 0, 0.9375),
    vec3(-0.42985743923670755, 0.3937846263287336, 0.8125),
    vec3(0.0634871954735437, -0.7234038471081724, 0.6875),
    vec3(0.50305559816796, 0.6561469463099526, 0.5625),
    vec3(-0.8854724951825381, -0.156627616578974, 0.4375),
    vec3(0.8014981392972829, -0.5098475092642832, 0.31250000000000006),
    vec3(-0.25500011945061624, 0.9485877339920497, 0.18749999999999994),
    vec3(-0.46000593484912655, -0.8857134355442402, 0.062499999999999986),
    vec3(0.9374848892962336, 0.3423679779728655, 0.062499999999999986),
    vec3(-0.9079519205901849, 0.3747893540331617, 0.18749999999999994),
    vec3(0.4026188380305669, -0.8603730709773035, 0.31249999999999994),
    vec3(0.26912156091066985, 0.8580019437349805, 0.4374999999999999),
    vec3(-0.7153542789226215, -0.41456242669481796, 0.5625000000000001),
    vec3(0.709246688607407, -0.15592589489699188, 0.6875),
    vec3(-0.33527813688580826, 0.4768986484845404, 0.8125),
    vec3(-0.04471982743159614, -0.34509982184070775, 0.9375)
);


//////////////////////////////////////////////////////
//              OTHER KERNELS
//////////////////////////////////////////////////////

// This kernel is progressive. Any sample count will return an even spread of noise
const vec2 blue_noise_disk[64] = vec2[](
    vec2(0.478712,0.875764),
    vec2(-0.337956,-0.793959),
    vec2(-0.955259,-0.028164),
    vec2(0.864527,0.325689),
    vec2(0.209342,-0.395657),
    vec2(-0.106779,0.672585),
    vec2(0.156213,0.235113),
    vec2(-0.413644,-0.082856),
    vec2(-0.415667,0.323909),
    vec2(0.141896,-0.939980),
    vec2(0.954932,-0.182516),
    vec2(-0.766184,0.410799),
    vec2(-0.434912,-0.458845),
    vec2(0.415242,-0.078724),
    vec2(0.728335,-0.491777),
    vec2(-0.058086,-0.066401),
    vec2(0.202990,0.686837),
    vec2(-0.808362,-0.556402),
    vec2(0.507386,-0.640839),
    vec2(-0.723494,-0.229240),
    vec2(0.489740,0.317826),
    vec2(-0.622663,0.765301),
    vec2(-0.010640,0.929347),
    vec2(0.663146,0.647618),
    vec2(-0.096674,-0.413835),
    vec2(0.525945,-0.321063),
    vec2(-0.122533,0.366019),
    vec2(0.195235,-0.687983),
    vec2(-0.563203,0.098748),
    vec2(0.418563,0.561335),
    vec2(-0.378595,0.800367),
    vec2(0.826922,0.001024),
    vec2(-0.085372,-0.766651),
    vec2(-0.921920,0.183673),
    vec2(-0.590008,-0.721799),
    vec2(0.167751,-0.164393),
    vec2(0.032961,-0.562530),
    vec2(0.632900,-0.107059),
    vec2(-0.464080,0.569669),
    vec2(-0.173676,-0.958758),
    vec2(-0.242648,-0.234303),
    vec2(-0.275362,0.157163),
    vec2(0.382295,-0.795131),
    vec2(0.562955,0.115562),
    vec2(0.190586,0.470121),
    vec2(0.770764,-0.297576),
    vec2(0.237281,0.931050),
    vec2(-0.666642,-0.455871),
    vec2(-0.905649,-0.298379),
    vec2(0.339520,0.157829),
    vec2(0.701438,-0.704100),
    vec2(-0.062758,0.160346),
    vec2(-0.220674,0.957141),
    vec2(0.642692,0.432706),
    vec2(-0.773390,-0.015272),
    vec2(-0.671467,0.246880),
    vec2(0.158051,0.062859),
    vec2(0.806009,0.527232),
    vec2(-0.057620,-0.247071),
    vec2(0.333436,-0.516710),
    vec2(-0.550658,-0.315773),
    vec2(-0.652078,0.589846),
    vec2(0.008818,0.530556),
    vec2(-0.210004,0.519896) 
);

const float sobel_horizontal[9] = float[](
    -1, 0, 1,
    -2, 0, 2,
    -1, 0, 1
);

const float sobel_vertical[9] = float[](
    -1, -2, -1,
    0, 0, 0,
    1, 2, 1
);


const vec2 TAAOffsets[9] = vec2[]( // Samples 9 points around each pixel, with uniform coverage
    // Top Row
    vec2(1./3, -1./3),
    vec2(1./3, 0),
    vec2(1./3,  1./3),
    // Middle Row
    vec2(0, -1./3),
    vec2(0, 0),
    vec2(0,  1./3),
    // Bottom Row
    vec2(-1./3, -1./3),
    vec2(-1./3, 0),
    vec2(-1./3,  1./3)
);
/* const vec2 TAAOffsets[4] = vec2[]( // Creates as 2x2 pattern around a given pixel
    vec2( 0.25, 0.25),
    vec2( 0.25, -.25),
    vec2( -.25, 0.25),
    vec2( -.25, -.25)
); */