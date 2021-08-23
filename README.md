# DrDestens MinecraftShaders

Supports versions 1.8.x to 1.17.x (I usually develop on 1.8.9 and 1.16.5)

labPBR support
 - Make sure your PBR Ressource pack is labPBR, else it won't work correctly
 - Supports Normals, Roughness, Reflectance, Emission, AO, Hardcoded Metals, Subsurface Scattering
 - Does not Support Porosity

## Features:

### Water Effects
<img src="https://user-images.githubusercontent.com/70536771/126915076-fc846988-835d-419d-baa5-abb99e6ef9ab.png" width="100%"/>
<img src="https://user-images.githubusercontent.com/70536771/126960742-88d08bb4-8c6e-415b-b1a0-3cc8b131aa7a.png" width="100%"/>

### Depth of Field
<img src="https://user-images.githubusercontent.com/70536771/126915028-5f016e61-2f29-4d14-8e8d-18ac73adaaec.png" width="100%"/>

### Physically Based Rendering
<img src="https://user-images.githubusercontent.com/70536771/125120834-57399b80-e0f3-11eb-8b70-11c5d7997bd9.png" width="100%"/>
<img src="https://user-images.githubusercontent.com/70536771/125115288-6c123100-e0eb-11eb-852a-38042e077436.png" width="100%"/>

### Ambient Occlusion
<table>
 <td>
  On:
  <img src="https://user-images.githubusercontent.com/70536771/126914993-9df7fb36-895f-4bde-ab06-ddae3bb903f6.png" width="100%"/>
 </td>
 <td>
  Off:
  <img src="https://user-images.githubusercontent.com/70536771/126914998-c8a84bed-91ad-4e5f-ad5c-abb09620147c.png" width="100%"/>
 </td>
</table>

### Full Feature List:

 - Screen Space Reflections
 - Depth of Field
 - Screen Space Ambient Occlusion
 - Temporal Anti-Aliasing
 - Physically Based Rendering
   - Support for LabPBR 1.3
     - Normals
     - Roughness
     - Reflectance
     - Emission
     - Ambient Occlusion
     - Metals
     - Subsurface Scattering
 - Various Water Effects
   - Waves and Bump
   - Refraction
   - Absorption
 - Godrays
 - Bloom
 - Motion Blur
 - Chromatic Aberration
   - When paired with DoF realistic Focus-Dependant CA
 - Smooth sky gradient

