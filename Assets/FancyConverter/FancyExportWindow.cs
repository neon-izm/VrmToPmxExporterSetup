using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using VRM;

namespace FancyConverter
{
    public class FancyExportingWindow : EditorWindow
    {
        private static FancyExportingWindow _window = null;
        [SerializeField] private GameObject _vrm;

        [MenuItem("FancyConverter/PmxConvertWindow")]
        private static void Init()
        {
            _window = GetWindow<FancyExportingWindow>("VRMをPMXに変換します");
            _window.Show();
        }

        private void OnGUI()
        {
            EditorGUILayout.LabelField("一発でそれっぽく変換します。シーン上に配置したVRMのrootを指定してください");
            _vrm = EditorGUILayout.ObjectField(_vrm, typeof(GameObject), true) as GameObject;

            if (GUILayout.Button("変換"))
            {
                if (_vrm == null || _vrm.GetComponentInChildren<VRMBlendShapeProxy>() == null)
                {
                    var maybeThisModel = FindObjectOfType<VRMMeta>();

                    if (maybeThisModel != null)
                    {
                        var ret = EditorUtility.DisplayDialog("VRM指定漏れ警告",
                            $"もしかして{maybeThisModel.Meta.Title} {maybeThisModel.name}をPMXに変換したいですか？", "変換", "違う");
                        if (ret)
                        {
                            _vrm = maybeThisModel.gameObject;
                        }
                        else
                        {
                            return;
                        }
                    }
                    else
                    {
                        if (EditorUtility.DisplayDialog("VRM指定漏れ", "vrmにシーン上のモデルを指定してください", "OK"))
                        {
                        }
                    }
                }

                ConvertToPmx(_vrm);
            }
        }

        private static void ConvertToPmx(GameObject vrmModel)
        {
            var meta = vrmModel.GetComponent<VRMMeta>();

            if (string.IsNullOrEmpty(meta.Meta.ContactInformation))
            {
                meta.Meta.ContactInformation = "internal use only";
            }

            var blendShapeProxy = vrmModel.GetComponentInChildren<VRMBlendShapeProxy>();

            var skinnedMeshRenderers = vrmModel.GetComponentsInChildren<SkinnedMeshRenderer>();
            foreach (var mesh in skinnedMeshRenderers)
            {
                BlendShapeProxyBaker.BakeBlendShapeProxyToMesh(vrmModel, mesh, blendShapeProxy.BlendShapeAvatar);
            }

            PMXExporter exporter = vrmModel.GetComponent<PMXExporter>();
            if (exporter == null)
            {
                exporter = vrmModel.AddComponent<PMXExporter>();
            }

            exporter.Init();
        }
    }
}