# Unity Shadow Recieving Unlit Shaders
A collection of Unity ShaderLab unlit material shaders that recieve and cast shadows.

### How to use it
Put any appropriate shader files into your project and create materials from them

- **UnlitFullShadows** - Object will both cast and recieve shadows
- **UnlitShadowReciever** - Object will recieve shadows but won't cast them
- **UnlitShadowCaster** - Object will only cast shadows, but won't recieve any
- **UnlitFullShadowsAdditionalLights** - Object will recieve shadows from all ligths that cast shadows. Potentially expensive, obv

### Isn't it technically a Lit shader then?
Officer, I swear, it's only the light's shadow attenuation, no angles or funky math was used.
