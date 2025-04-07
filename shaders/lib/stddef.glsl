
// Buffer Defaults

#define LIGHTING_BUF_MAX_SKY   vec4(0, 1, 1, 1)
#define LIGHTING_BUF_MAX_BLOCK vec4(1, 0, 1, 1)


// Conditional interpolation qualifiers

#ifdef OPTIMIZE_INTERPOLATION

#define OPT_FLAT flat
#define OPT_NOPERSPECTIVE noperspective

#else 

#define OPT_FLAT smooth
#define OPT_NOPERSPECTIVE smooth

#endif

// Macro shorthands

#define SUPPORTS_RENDERSTAGE ( MC_VERSION >= 11605 )


#if defined DISTANT_HORIZONS
    #define DH(expression) expression
#else 
    #define DH(expression) 
#endif