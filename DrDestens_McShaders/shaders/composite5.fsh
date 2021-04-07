#version 130

#include "/lib/framebuffer.glsl"

#define DOF_MODE 3                   // Lens Blur Mode                                          [0 3 4]
#define DOF_STEPS 3                  // Depth of Field Step Size                                [1 2 3 4 5 6 7 8 9 10]
#define DOF_STRENGTH 1.0             // Depth of Field Intensity                                [0.25 0.5 1.0 1.5 2.0 2.5 3 3.5]

#define DOF_RANDOMIZE                // Randomize Samples in order to conceil high step sizes   
#define DOF_RANDOMIZE_AMOUNT 0.5     // Amount of randomization                                 [0.2 0.3 0.4 0.5 0.6 0.7 0.8]

#define DOF_DOWNSAMPLING 0.5         // How much downsampling takes place for the DoF effect    [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define DOF_KERNEL_SIZE 2            // Bokeh Quality                                           [1 2 3 4]           
#define DOF_MAXSIZE 0.005            // Maximum Blur                                            [0.002 0.005 0.007 0.01 1.0]

#define FOCUS_SPEED 1.0

uniform float centerDepthSmooth;
const float centerDepthHalflife = 1.0;

const bool colortex0MipmapEnabled = true;

varying vec2 coord;
varying vec2 screenResolution;
varying vec2 pixelSize;

uniform mat4 gbufferProjection;

uniform int frameCounter;
uniform float near;
uniform float far;


/* --------------------------------------------------------
                Disk Kernels for DoF offsets 
               Calculated using the Vogel method
 --------------------------------------------------------- */

const vec2 DOFoffsetLow_polar[4] = vec2[4](
    vec2(0.3535533905932738, 0),
    vec2(0.6123724356957945, 2.399963229728653),
    vec2(0.7905694150420949, 4.799926459457306),
    vec2(0.9354143466934853, 7.199889689185959)
);

const vec2 DOFoffsetMedium_polar[16] = vec2[16](
    vec2(0.1767766952966369, 0),
    vec2(0.30618621784789724, 2.399963229728653),
    vec2(0.39528470752104744, 4.799926459457306),
    vec2(0.46770717334674267, 7.199889689185959),
    vec2(0.5303300858899106, 9.599852918914612),
    vec2(0.5863019699779287, 11.999816148643266),
    vec2(0.6373774391990981, 14.399779378371917),
    vec2(0.6846531968814576, 16.799742608100573),
    vec2(0.7288689868556626, 19.199705837829224),
    vec2(0.770551750371122, 21.599669067557876),
    vec2(0.8100925873009825, 23.99963229728653),
    vec2(0.8477912478906585, 26.399595527015183),
    vec2(0.8838834764831844, 28.799558756743835),
    vec2(0.9185586535436918, 31.19952198647249),
    vec2(0.9519716382329886, 33.599485216201145),
    vec2(0.9842509842514764, 35.999448445929794)
);

const vec2 DOFoffsetHigh_polar[32] = vec2[32](
    vec2(0.125, 0),
    vec2(0.21650635094610962, 2.399963229728653),
    vec2(0.2795084971874737, 4.799926459457306),
    vec2(0.3307189138830738, 7.199889689185959),
    vec2(0.37499999999999994, 9.599852918914612),
    vec2(0.414578098794425, 11.999816148643266),
    vec2(0.4506939094329986, 14.399779378371917),
    vec2(0.48412291827592707, 16.799742608100573),
    vec2(0.5153882032022076, 19.199705837829224),
    vec2(0.5448623679425841, 21.599669067557876),
    vec2(0.57282196186948, 23.99963229728653),
    vec2(0.5994789404140899, 26.399595527015183),
    vec2(0.625, 28.799558756743835),
    vec2(0.649519052838329, 31.19952198647249),
    vec2(0.673145600891813, 33.599485216201145),
    vec2(0.6959705453537527, 35.999448445929794),
    vec2(0.7180703308172536, 38.39941167565845),
    vec2(0.739509972887452, 40.799374905387104),
    vec2(0.7603453162872774, 43.19933813511575),
    vec2(0.7806247497997998, 45.59930136484441),
    vec2(0.8003905296791061, 47.99926459457306),
    vec2(0.81967981553775, 50.39922782430171),
    vec2(0.8385254915624211, 52.799191054030366),
    vec2(0.8569568250501305, 55.19915428375902),
    vec2(0.8749999999999999, 57.59911751348767),
    vec2(0.8926785535678562, 59.999080743216325),
    vec2(0.9100137361600648, 62.39904397294498),
    vec2(0.9270248108869578, 64.79900720267364),
    vec2(0.9437293044088436, 67.19897043240229),
    vec2(0.960143218483576, 69.59893366213093),
    vec2(0.9762812094883317, 71.99889689185959),
    vec2(0.9921567416492214, 74.39886012158824)
);

const vec2 DOFoffsetVeryHigh_polar[64] = vec2[64](
    vec2(0.08838834764831845, 0),
    vec2(0.15309310892394862, 2.399963229728653),
    vec2(0.19764235376052372, 4.799926459457306),
    vec2(0.23385358667337133, 7.199889689185959),
    vec2(0.2651650429449553, 9.599852918914612),
    vec2(0.29315098498896436, 11.999816148643266),
    vec2(0.31868871959954903, 14.399779378371917),
    vec2(0.3423265984407288, 16.799742608100573),
    vec2(0.3644344934278313, 19.199705837829224),
    vec2(0.385275875185561, 21.599669067557876),
    vec2(0.4050462936504913, 23.99963229728653),
    vec2(0.42389562394532926, 26.399595527015183),
    vec2(0.4419417382415922, 28.799558756743835),
    vec2(0.4592793267718459, 31.19952198647249),
    vec2(0.4759858191164943, 33.599485216201145),
    vec2(0.4921254921257382, 35.999448445929794),
    vec2(0.5077524002897476, 38.39941167565845),
    vec2(0.5229125165837972, 40.799374905387104),
    vec2(0.5376453291901642, 43.19933813511575),
    vec2(0.5519850541454905, 45.59930136484441),
    vec2(0.5659615711335886, 47.99926459457306),
    vec2(0.5796011559684815, 50.39922782430171),
    vec2(0.5929270612815711, 52.799191054030366),
    vec2(0.6059599821770412, 55.19915428375902),
    vec2(0.6187184335382291, 57.59911751348767),
    vec2(0.6312190586476298, 59.999080743216325),
    vec2(0.6434768838116876, 62.39904397294498),
    vec2(0.6555055301063447, 64.79900720267364),
    vec2(0.667317390751957, 67.19897043240229),
    vec2(0.6789237807000135, 69.59893366213093),
    vec2(0.6903350635742038, 71.99889689185959),
    vec2(0.701560760020114, 74.39886012158824),
    vec2(0.7126096406869612, 76.7988233513169),
    vec2(0.7234898064243891, 79.19878658104555),
    vec2(0.7342087577794206, 81.59874981077421),
    vec2(0.7447734554883115, 83.99871304050286),
    vec2(0.7551903733496608, 86.3986762702315),
    vec2(0.7654655446197431, 88.79863949996016),
    vec2(0.7756046028744286, 91.19860272968882),
    vec2(0.7856128181235335, 93.59856595941747),
    vec2(0.795495128834866, 95.99852918914613),
    vec2(0.8052561704203204, 98.39849241887478),
    vec2(0.8149003006503311, 100.79845564860342),
    vec2(0.8244316223920575, 103.19841887833208),
    vec2(0.8338540040078959, 105.59838210806073),
    vec2(0.8431710977020026, 107.99834533778939),
    vec2(0.852386356061616, 110.39830856751804),
    vec2(0.8615030470056388, 112.7982717972467),
    vec2(0.8705242673240075, 115.19823502697534),
    vec2(0.879452954966893, 117.598198256704),
    vec2(0.8882919002219934, 119.99816148643265),
    vec2(0.8970437559004577, 122.3981247161613),
    vec2(0.9057110466368399, 124.79808794588996),
    vec2(0.9142961773954871, 127.19805117561862),
    vec2(0.9228014412645875, 129.59801440534727),
    vec2(0.9312290266094587, 131.99797763507593),
    vec2(0.9395810236483068, 134.39794086480458),
    vec2(0.9478594305064438, 136.79790409453324),
    vec2(0.9560661587986472, 139.19786732426186),
    vec2(0.9642030387838445, 141.59783055399052),
    vec2(0.9722718241315028, 143.99779378371917),
    vec2(0.9802741963348827, 146.39775701344783),
    vec2(0.9882117688026185, 148.79772024317649),
    vec2(0.9960860906568267, 151.19768347290514)
);

const vec2 DOFoffsetLow[4] = vec2[4](
    vec2(0.3535533905932738, 0),
    vec2(-0.451544375875096, 0.4136516367857983),
    vec2(0.06911610404911818, -0.7875423570583817),
    vec2(0.5691424396454711, 0.7423455283049809)
);

const vec2 DOFoffsetMedium[16] = vec2[16](
    vec2(0.1767766952966369, 0),
    vec2(-0.225772187937548, 0.20682581839289915),
    vec2(0.03455805202455909, -0.39377117852919086),
    vec2(0.28457121982273553, 0.37117276415249045),
    vec2(-0.5222231872442845, -0.09237392870513249),
    vec2(0.4946953915278165, -0.3146847145972304),
    vec2(-0.16546592706317265, 0.6155250011016001),
    vec2(-0.31556146793512924, -0.6075944041501916),
    vec2(0.6846421615837076, 0.25003021933756037),
    vec2(-0.7122560862297537, 0.294008958415681),
    vec2(0.34335449874552143, -0.7337286202617503),
    vec2(0.2537302409112575, 0.8089319902483244),
    vec2(-0.7647458919689066, -0.4431858760347418),
    vec2(0.897133983572641, -0.19723238962980807),
    vec2(-0.5475069048541611, 0.7787722318733614),
    vec2(-0.12648677292149527, -0.9760896968393356)
);

const vec2 DOFoffsetHigh[32] = vec2[32](
    vec2(0.125, 0),
    vec2(-0.15964504509396382, 0.14624793871007635),
    vec2(0.024436232931163232, -0.2784382705738095),
    vec2(0.20122223926718397, 0.26245877852398103),
    vec2(-0.36926755699328573, -0.06531823139224185),
    vec2(0.3498024659710532, -0.22251569562745496),
    vec2(-0.11700207908168804, 0.4352419022687985),
    vec2(-0.22313565385811113, -0.42963412338560025),
    vec2(0.48411511514205563, 0.17679806359514877),
    vec2(-0.5036411085144491, 0.20789572822532165),
    vec2(0.2427882944138661, -0.5188244829377329),
    vec2(0.17941437394044654, 0.5720012958233203),
    vec2(-0.5407570060957687, -0.31337973827026655),
    vec2(0.6343695234171152, -0.13946436017686456),
    vec2(-0.38714584516883516, 0.5506751261574362),
    vec2(-0.08943965486319227, -0.6901996436814155),
    vec2(0.5490717571262015, 0.46275825819356864),
    vec2(-0.7388784713095301, 0.03055494453098949),
    vec2(0.5389551252122559, -0.5363323344787647),
    vec2(-0.03605818593008708, 0.7797915152317517),
    vec2(-0.5128175319077373, -0.6145267927178252),
    vec2(0.8123595934142241, 0.10930183432987865),
    vec2(-0.6883106405074308, 0.4789086156713513),
    vec2(0.18808605734703482, -0.8360613823348426),
    vec2(0.4350332655946333, 0.75919105489071),
    vec2(-0.8504484103424857, -0.27131623863296295),
    vec2(0.8261024011261134, -0.3816802625937971),
    vec2(-0.3578882017213956, 0.8551555619117643),
    vec2(-0.31940733428433593, -0.8880337576947028),
    vec2(0.8499086353959916, 0.4466881590990781),
    vec2(-0.9440346462300179, 0.2488445030885048),
    vec2(0.536595808250202, -0.8345297709299007)
);

const vec2 DOFoffsetVeryHigh[64] = vec2[64](
    vec2(0.08838834764831845, 0),
    vec2(-0.112886093968774, 0.10341290919644958),
    vec2(0.017279026012279545, -0.19688558926459543),
    vec2(0.14228560991136777, 0.18558638207624523),
    vec2(-0.26111159362214226, -0.046186964352566244),
    vec2(0.24734769576390825, -0.1573423572986152),
    vec2(-0.08273296353158632, 0.30776250055080007),
    vec2(-0.15778073396756462, -0.3037972020750958),
    vec2(0.3423210807918538, 0.12501510966878018),
    vec2(-0.35612804311487684, 0.1470044792078405),
    vec2(0.17167724937276072, -0.36686431013087517),
    vec2(0.12686512045562875, 0.4044659951241622),
    vec2(-0.3823729459844533, -0.2215929380173709),
    vec2(0.4485669917863205, -0.09861619481490404),
    vec2(-0.27375345242708055, 0.3893861159366807),
    vec2(-0.06324338646074763, -0.4880448484196678),
    vec2(0.3882523628219502, 0.32721950241874764),
    vec2(-0.5224659775357187, 0.02160560847664148),
    vec2(0.3810988237928309, -0.37924423067954616),
    vec2(-0.025496987788449936, 0.5513958683321046),
    vec2(-0.3626167543233098, -0.4345360623515941),
    vec2(0.5744249772651445, 0.07728806825078578),
    vec2(-0.48670912146566037, 0.3386395297098746),
    vec2(0.13299692659673018, -0.591184672937166),
    vec2(0.3076149721436936, 0.5368291431293896),
    vec2(-0.6013578380024912, -0.19184955218339567),
    vec2(0.5841426097907643, -0.2698887019251361),
    vec2(-0.2530651743438579, 0.6046862967972011),
    vec2(-0.2258550920331724, -0.6279346919884959),
    vec2(0.6009761594775107, 0.31585622637469357),
    vec2(-0.6675333000242891, 0.17595963559487854),
    vec2(0.3794305347699942, -0.5901016601265889),
    vec2(0.12069909342891681, 0.7023134833145649),
    vec2(-0.5720078077939695, -0.44299499751434795),
    vec2(0.731701930078265, -0.06062000923574415),
    vec2(-0.5057602714083884, 0.5467120337663267),
    vec2(0.003684027952365215, -0.7551813874414849),
    vec2(0.514304945229712, 0.5669461379286951),
    vec2(-0.7722948658519765, -0.07157611458215449),
    vec2(0.6257873078318013, -0.47495025566539767),
    vec2(-0.14238056851320097, 0.782649521631399),
    vec2(-0.42888394095723925, -0.6815394817536159),
    vec2(0.785920133036245, 0.21538812522581444),
    vec2(-0.7334855212372673, 0.3764126593717251),
    vec2(0.2898616761608319, -0.7818521015468547),
    vec2(0.31791146893355565, 0.7809416098022366),
    vec2(-0.77026392317357, -0.3650424477471912),
    vec2(0.8232633014643855, -0.2538208747561163),
    vec2(-0.44015653024869994, 0.751049085532647),
    vec2(-0.1846432401149469, -0.8598513673187094),
    vec2(0.7241773560320561, 0.5144216723762915),
    vec2(-0.8901573611276761, 0.11093859756735677),
    vec2(0.5870542621401351, -0.6896954351763548),
    vec2(0.033319899649036984, 0.913688833404118),
    vec2(-0.6477269570369681, -0.6572764175958464),
    vec2(0.9300141309321251, 0.047552247755117134),
    vec2(-0.7243231135792285, 0.5984718265172488),
    vec2(0.1309753226146144, -0.9387667254786982),
    vec2(0.5422048902753999, 0.7874492726274129),
    vec2(-0.9396490219009803, -0.21621104421497742),
    vec2(0.8459367503175589, -0.47927394511090204),
    vec2(-0.3024918972101173, 0.9324356021314415),
    vec2(-0.41009709429808805, -0.8991011473957005),
    vec2(0.9169758677396763, 0.3890279655539787)
);



//Depth of Field

vec3 boxBlur(vec2 coord, float size, float stepsize) {
    if (size <= pixelSize.x * 0.5)               { return getAlbedo(coord); } //Return unblurred if <1 pixel
    stepsize *= pixelSize.x;
    if (stepsize > size)                   { stepsize = size; } //Prevent blur from clipping due to lange step size

    vec3 pixelColor = vec3(0);

    float samplecount = 0.0;

    // Enable or Disable Coordinate Randomization, making use of precompiler
    #ifdef DOF_RANDOMIZE
        float randfac1 = rand_11(coord);
        float randfac2 = rand_11(coord + 1);
    #endif        
    
    for (float i = -size; i < size; i += stepsize) {
        for (float o = -size; o < size; o += stepsize) {
            vec2 sampleCoord = vec2(coord.x + i, coord.y + o);

            // Enable or Disable Coordinate Randomization, making use of precompiler
            #ifdef DOF_RANDOMIZE
            sampleCoord += vec2(randfac1, randfac2) * (stepsize - pixelSize.x) * 0.5;
            #endif 


            pixelColor += getAlbedo(sampleCoord);
            
            samplecount++;
        }
    }

    pixelColor /= samplecount;
    return pixelColor;
}

vec3 boxBlur_exp(vec2 coord, float size, float stepsize) {
    if (size <= pixelSize.x * 0.1 || getDepth(coord).x < 0.56)               { return getAlbedo(coord); } //Return unblurred if <1 pixel
    stepsize *= pixelSize.x;
    if (stepsize > size)                         { stepsize = size; } //Prevent blur from clipping due to lange step size

    vec3 pixelColor = vec3(0);

    float samplecount = 0.0;

    // Enable or Disable Coordinate Randomization, making use of precompiler
    #ifdef DOF_RANDOMIZE
        float randfac1 = randf_01(coord) * 2 -1;
        float randfac2 = randfac1;
    #endif
    
    for (float i = -size; i < size; i += stepsize) {
        for (float o = -size; o < size; o += stepsize) {
            vec2 sampleCoord = vec2(coord.x + i, coord.y + o);

            // Enable or Disable Coordinate Randomization, making use of precompiler
            #ifdef DOF_RANDOMIZE
            sampleCoord += vec2(randfac1, randfac2) * (stepsize - pixelSize.x) * DOF_RANDOMIZE_AMOUNT;
            #endif 

            // I am using texelFetch instead of textur2D, in order to avoid linear interpolation. This increases performance
            sampleCoord.x = clamp(sampleCoord.x, 0, 1 - pixelSize.x);
            sampleCoord.y = clamp(sampleCoord.y, 0, 1 - pixelSize.y);
            ivec2 intcoords = ivec2(sampleCoord * vec2(viewWidth, viewHeight));

            pixelColor += texelFetch(colortex0, intcoords, 0).rgb;
            
            //pixelColor += getAlbedo(sampleCoord);

            samplecount++;
        }
    }

    pixelColor /= samplecount;
    return pixelColor;
}

vec3 bokehBlur(vec2 coord, float size, float stepsize) {
    if (size <= pixelSize.x * 0.5 || getDepth(coord).x < 0.56)               { return getAlbedo(coord); } //Return unblurred if <0.5 pixel

    vec3 pixelColor = vec3(0);
    float lod = log2(size / pixelSize.x) * DOF_DOWNSAMPLING; // Level of detail for Mipmapped Texture (higher -> less pixels)


    // Low Quality
    #if DOF_KERNEL_SIZE == 1
        int kernelSize = 4;
        vec2[] kernel = DOFoffsetLow;

    // Medium Quality
    #elif DOF_KERNEL_SIZE == 2
        int kernelSize = 16;
        vec2[] kernel = DOFoffsetMedium;
    
    // High Quality
    #elif DOF_KERNEL_SIZE == 3
        int kernelSize = 32;
        vec2[] kernel = DOFoffsetHigh;

    // Very High Quality
    #elif DOF_KERNEL_SIZE == 4
        int kernelSize = 64;
        vec2[] kernel = DOFoffsetVeryHigh;
    #endif


    for (int i = 0; i < kernelSize; i++) {
        pixelColor += textureLod(colortex0, blurOffset(coord, lod) + (kernel[i] * size), lod).rgb;
    }


    pixelColor /= kernelSize;
    return pixelColor;
}

vec3 bokehBlur_adaptive(vec2 coord, float size, float stepsize) {
    if (size <= pixelSize.x * 0.5 || getDepth(coord).x < 0.56)               { return getAlbedo(coord); } //Return unblurred if <0.5 pixel

    vec3 pixelColor = vec3(0);
    float pixelBlur = size / pixelSize.x;

    float lod = log2(pixelBlur) * DOF_DOWNSAMPLING; // Level of detail for Mipmapped Texture (higher -> less pixels)

    // Low Quality
    #if DOF_KERNEL_SIZE == 1
        int lowKernelSize = 4;
        vec2[] lowKernel = DOFoffsetLow;

        int mediumKernelSize = 4;
        vec2[] mediumKernel = DOFoffsetLow;

        int highKernelSize = 16;
        vec2[] highKernel = DOFoffsetMedium;

    // Medium Quality
    #elif DOF_KERNEL_SIZE == 2
        int lowKernelSize = 4;
        vec2[] lowKernel = DOFoffsetLow;

        int mediumKernelSize = 16;
        vec2[] mediumKernel = DOFoffsetMedium;

        int highKernelSize = 32;
        vec2[] highKernel = DOFoffsetHigh;

    // High Quality
    #elif DOF_KERNEL_SIZE >= 3
        int lowKernelSize = 16;
        vec2[] lowKernel = DOFoffsetMedium;

        int mediumKernelSize = 32;
        vec2[] mediumKernel = DOFoffsetHigh;

        int highKernelSize = 64;
        vec2[] highKernel = DOFoffsetVeryHigh;

    #endif

    if (pixelBlur < 4) { // Under 4 pixel blur 

        for (int i = 0; i < lowKernelSize; i++) {
            pixelColor += textureLod(colortex0, blurOffset(coord, lod) + (lowKernel[i] * size), lod).rgb;
        }
        pixelColor /= lowKernelSize;

    } else if (pixelBlur < 8) { // under 8 pixel blur

        for (int i = 0; i < mediumKernelSize; i++) {
            pixelColor += textureLod(colortex0, blurOffset(coord, lod) + (mediumKernel[i] * size), lod).rgb;
        }
        pixelColor /= mediumKernelSize;

    } else { // over 8 pixel blur

        for (int i = 0; i < highKernelSize; i++) {
            pixelColor += textureLod(colortex0, blurOffset(coord, lod) + (highKernel[i] * size), lod).rgb;
        }

        pixelColor /= highKernelSize;
    } 

    return pixelColor;
}

vec3 DoF(vec2 coord, float pixeldepth, float size, float stepsize) {

        size = min(size, DOF_MAXSIZE);
    

    // Use precompiler instead if runtime - saves ressources
    #if DOF_MODE == 2
        return boxBlur_exp(coord, size * 0.70710, stepsize);
    #elif DOF_MODE == 3
        return bokehBlur(coord, size * 1, stepsize);
    #elif DOF_MODE == 4
        return bokehBlur_adaptive(coord, size * 1, stepsize);
    #endif

    #if DOF_MODE == 0
        return vec3(0);
    #endif
}

float CoC(float depth) {
    depth = (depth * 4) - 3;
    depth *= depth;
    return depth;
}

/* DRAWBUFFERS:0 */

void main() {
    vec3 color          = getAlbedo(coord);
    float depth         = getDepth(coord);

    // Disables Depth of Field in the precompiler
    #if DOF_MODE != 0

        float fovScale = gbufferProjection[1][1] * 0.7299270073;

        float mappedDepth   = CoC(depth);
        float lookDepth     = CoC(centerDepthSmooth); //Depth of center pixel (mapped)
        float blurDepth     = abs(mappedDepth - lookDepth) * DOF_STRENGTH * 0.02 * fovScale; 

        color = DoF(coord, depth, blurDepth, DOF_STEPS); // DOF_MODE, DOF_STEPS -> Settings Menu

    #endif

    //Pass everything forward
    
    COLORTEX_0          = vec4(color,  1);
}