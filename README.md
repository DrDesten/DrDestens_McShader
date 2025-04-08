# DrDestens MinecraftShaders

Requires Optifine or Iris.  
Supports Minecraft versions 1.8.9 and newer.  

labPBR and OldPBR/SeusPBR support
 - Supports Normals, Roughness, Reflectance, Emission, AO, Hardcoded Metals, Subsurface Scattering, Height (LabPBR)
 - Supports Normals, Roughness, Emission, Metalness, Height (OldPBR/SeusPBR)

## Images:
<img src="https://raw.githubusercontent.com/DrDesten/DrDestens_McShader/v2/images/DoF%20Water%20Vegetation.png" width="100%"/>
<img src="https://raw.githubusercontent.com/DrDesten/DrDestens_McShader/v2/images/Nether%20Crimson%20Forest.png" width="100%"/>
<img src="https://raw.githubusercontent.com/DrDesten/DrDestens_McShader/v2/images/PBR%20Reflections%20Diamond.png" width="100%"/>
<img src="https://raw.githubusercontent.com/DrDesten/DrDestens_McShader/v2/images/PBR%20Reflections%20Fire%20Iron.png" width="100%"/>

### Full Feature List:

### Lighting

 - PBR  
&emsp;Enables Physically Based Rendering  
&emsp;Make sure you enable Normal and Specular mapsm in the OptiFine shader options
 - PBR Format - *LabPBR 1.3, SeusPBR / OldPBR*
 - Resource Pack Resolution
 - **Physically Based Rendering**
   - Height as AO  
&emsp;Uses the Height information for Ambient occlusion
   - Normal Mapping Fix  
&emsp;With newer OptiFine versions this might not be necessary  
&emsp;Enable this if normal maps do not show on entities or handheld objects
   - Use Hardcoded Metals  
&emsp;If disabled, the shader will use the color for the reflectance data  
&emsp;LabPBR only
   - Subsurface Scattering
   - Parallax Occlusion Mapping  
&emsp;Adds additional detail to blocks using the height map  
&emsp;Low performance impact  
&emsp;Can create artifacts at screen borders
   - **POM Options**
     - POM Depth  
&emsp;Specifies how deep the POM goes  
&emsp;Higher values will create artifacts
     - POM Distortion  
&emsp;Exaggerates the height map  
&emsp;Helps create more depth with small POM Depth values  
&emsp;Creates artifacts when used with high POM Depth values
     - Smooth POM  
&emsp;Smooths out the height map  
&emsp;Significantly reduces artifacts
 - Skylight AO  
&emsp;Specifies the amount of ambient occlusion on skylight
 - Blocklight AO  
&emsp;Specifies the amount of ambient occlusion on blocklight
 - Skylight Gamma  
&emsp;Higher = Darker  
&emsp;Lower = Brighter
 - Blocklight Gamma  
&emsp;Higher = Darker  
&emsp;Lower = Brighter
 - Minimum Light  
&emsp;Restricts blocklight to never go below this value  
&emsp;Prevents caves from being pitch black (unless you set it to zero that is)
 - **Lightmap Colors**
   - Nether Ambient Brightness
   - End Ambient Brightness
   - End Ambient Saturation
   - Skylight Day *(RGB Color Picker)*
   - Skylight Night *(RGB Color Picker)*
   - Blocklight *(RGB Color Picker)*  
&emsp;Select blocklight color (torches, glowstone, etc.)  
&emsp;If "Complex Blocklight" is enabled, this color will **NOT** be used
   - Complex Blocklight  
&emsp;Allows you to select two colors for blocklight  
&emsp;One for dark parts, one for bright parts
   - Blend Curve  
&emsp;Higher: Emphasize "Bright" color  
&emsp;Lower: Emphasize "Dark" color  
&emsp;50 = linear transition
   - Complex Blocklight Dark *(RGB Color Picker)*
   - Complex Blocklight Bright *(RGB Color Picker)*

### Depth Of Field

 - Depth of Field  
&emsp;Blurs non-focused objects, like a real camera
 - Bokeh Samples  
&emsp;Quality of the blur  
&emsp;Higher is better  
&emsp;Significantly affects performance
 - DoF Intensity  
&emsp;Intensity of the Depth of Field effect  
&emsp;Low performance impact
 - Maximum Blur - *High, Unlimited*  
&emsp;Limits the strength of the DoF blur  
&emsp;Helps reduce artifacts when using lower sample counts and is better for gameplay
 - DoF Downsampling Amount  
&emsp;Amount of Downsampling that takes place for the Depth of Field effect  
&emsp;Reduces DoF artifacts, increases pixelation artifacts  
&emsp;No/Low performance impact
 - Far Blur Only  
&emsp;Only blurs far away things
 - Sample Rejection  
&emsp;Improved DoF Quality by (mostly) removing color bleeding  
&emsp;Can have a significant performance impact
 - Focus Delay  
&emsp;Sets how long the focus takes to adjust

### Reflections

 - Reflection Mode - *OFF, Sky, Flipped Image, Raytraced*
 - Raytracing Quality  
&emsp;Number of raytracing iterations  
&emsp;Lower is faster
 - Thickness Estimation Modifier - *Infinite*  
&emsp;Increase this if the reflection blind spots annoy you  
&emsp;Influences assumption about how thick a pixel is  
&emsp;No performance impact
 - Fade Edges
 - Reflection Threshold  
&emsp;PBR only  
&emsp;Sets the minimum required reflectiveness in order for SSR to enable  
&emsp;Higher values may introduce reflection cutoffs
 - Screen Space Refraction  
&emsp;Distorts things seen through water
 - Refraction Strength
 - Glass Reflections  
&emsp;Adds reflections to tinted glass blocks

### Water

 - Waving Water  
&emsp;"Physical" Waves  
&emsp;Moves the water surface
 - Wave Height
 - Wave Normals - *OFF, Noise, Sine*
 - Normals Strength  
&emsp;Fake Waves, pretending to be real ones  
&emsp;Added detail
 - Normals Scale
 - Water Absorption Density
 - Water Absorption Bias  
&emsp;Adds a constant to the water fog distance  
&emsp;Can help in making water more visible
 - Water Texture  
&emsp;Enables the vanilla water texture
 - **Water Color Options**
   - Water Absorption *(RGB Color Picker)*
   - Absorption Color Multiplier

### Camera and Tonemapping

 - Exposure
 - Tonemapping - *Custom Reinhard, Unreal*
 - Contrast
 - Vibrance
 - Saturation
 - Brightness
 - Vignette - *OFF, Round, Square*  
&emsp;Darkens screen borders
 - Vignette Strength

### Post Processing

 - TAA
&emsp;Temporal Anti-Aliasing  
&emsp;Smooths edges at the cost of a slightly blurrier image  
&emsp;Might cause problems with OptiFine's high-res screenshot feature
 - **TAA Options**
   - TAA Blending Constant  
&emsp;Controls the opacity of the current frame  
&emsp;Set this value lower for smoother TAA
   - TAA Sharpening  
&emsp;Changes the strength of the sharpening effect
 - Bloom  
&emsp;Creates a glow around bright objects  
&emsp;Looks nice ;)
 - Bloom Strength
 - Motion Blur
 - Motion Blur Intensity
 - SSAO  
&emsp;Screen Space Ambient Occlusion  
&emsp;Makes cavities dark  
&emsp;High performance impact
 - SSAO Quality - *Low, Medium, High*
 - SSAO Strength

### Atmospherics

 - Fog - *OFF, Normal, Border*
 - Fog Amount
 - Morning Fog  
&emsp;Increases fog amount during sunsets  
&emsp;Only works with fog in "Normal" mode  
&emsp;Requires fog and sunsets to be enabled
 - Morning Fog Strength
 - Cave Fog
 - Cave Fog Brightness
 - Godrays
 - **Godray Colors**
   - Godray Sun *(RGB Color Picker)*
   - Godray Moon *(RGB Color Picker)*
 - Godray Strength
 - Godray Radius
 - Godray Samples
 - **Sky Colors**
   - Sky Noon *(RGB Color Picker)*
   - Sky Sunset *(RGB Color Picker)*
   - Sky Midnight *(RGB Color Picker)*
   - End Sky Upper *(RGB Color Picker)*
   - End Sky Lower *(RGB Color Picker)*
 - Sun Angle

### Weather

 - Rain Detection - *Temperature, Color*
 - Rain Opacity
 - Rain Refraction
 - Rain Refraction Strength

### Other Stuff

 - Outline - *OFF, White, Black, Rainbow*
 - Outline Distance
 - Block Selection Outline - *Black, White, Rainbow*  
&emsp;**Only works with newer OptiFine versions (G7 or higher)**
 - Block Selection Outline Opacity
 - Wavy Blocks
 - Wavy Leaves
 - World Curvature
 - World Radius
 - Hand Invisibility Effect  
&emsp;Distorts handheld objects when invisible
 - White World
 - Directional Lightmaps  
&emsp;Applies normal mapping to dynamic lights  
&emsp;Requires a ressource pack with PBR support
 - Directional Lightmap Strength
 - Dynamic Light Brightness  
&emsp;Changes the brightness of light from emissive blocks

### Optimisation

 - Flat Vertices  
&emsp;Disable when using custom models with smooth surfaces
