
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