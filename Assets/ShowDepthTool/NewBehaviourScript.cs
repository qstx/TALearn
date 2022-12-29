using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class NewBehaviourScript
{
    [MenuItem("Tools/Reset SceneView Shaders")]
    static void ResetSceneViewShaders()
    {
        Shader shader = Shader.Find("Unlit/ShowDepthShader");
        ((SceneView)SceneView.sceneViews[0]).SetSceneViewShaderReplace(shader, null);
        //SceneView.currentDrawingSceneView.SetSceneViewShaderReplace(shader, "Transparent");
    }

    [MenuItem("Tools/Clear SceneView")]
    static void SceneViewClearSceneView()
    {
        ((SceneView)SceneView.sceneViews[0]).SetSceneViewShaderReplace(null, null);
    }
}
