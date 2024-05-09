
// Conditional interpolation qualifiers
#ifdef OPTIMIZE_INTERPOLATION

#define OPT_FLAT flat
#define OPT_NOPERSPECTIVE noperspective

#else 

#define OPT_FLAT smooth
#define OPT_NOPERSPECTIVE smooth

#endif