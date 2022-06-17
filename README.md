# VrmToPmxExporterSetup
PMXExporter v0.5.6 by Furia https://twitter.com/flammpfeil/status/1032266829597573121  
を使ってPMXファイルを生成する際に、一部のVRMファイルで互換性の問題が生じることがあったので書き換えを行い、Unityプロジェクト形式として配布します。

具体的には
- モデリング過程で顔のメッシュの基点を原点以外にしているモデル
- VrmBlendShapeProxyで複数メッシュにまたがるBlendShapeKeyが打たれている

ようなVRMファイルに対して効果があると期待しています

# Environment
- Unity2020.3.9f1 (or later)

# Usage
1. UnityEditorでプロジェクトを開きます
2. vrmファイルをプロジェクトにインポートします 
3. ヒエラルキービューにvrmファイルをドラッグアンドドロップしてモデルをシーン上に配置します
4. UnityEditorのメニューからFancyConverter/PmxConvertWindowを選びます
5． PmxConvertWindow内の vrmに先ほど配置したモデルを指定します
6. PmxConvertWindow内の変換ボタンを押します
7. 数分待つとpmxファイルが生成されます


# include
- PMXExporter v0.5.6 by Furia　
- UniVRM 0.5.6
- MMDataIO(zyando)
# License
プロジェクト独自コードはMIT、それ以外は使用したライブラリのライセンスに準じます。

# For other developer
see diff commit


