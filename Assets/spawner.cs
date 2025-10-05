using UnityEngine;
using System.Runtime.InteropServices;

public class spawner : MonoBehaviour
{
    public Mesh grassMesh;
    public Material grassMaterial;
    public ComputeShader grassCompute;

    public Texture2D hightMap;

    public int grassCount = 1000;

    public float hightScale = 1;

    ComputeBuffer grassBuffer;
    ComputeBuffer argsBuf;

    int kernel;
    uint threadGroupX;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        int stride = Marshal.SizeOf(typeof(GrassData));
        grassBuffer = new ComputeBuffer(grassCount, stride, ComputeBufferType.Structured);

        uint[] args = new uint[5] {
            grassMesh.GetIndexCount(0), (uint)grassCount,
            grassMesh.GetIndexStart(0), grassMesh.GetBaseVertex(0), 0
        };

        argsBuf = new ComputeBuffer(1, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);
        argsBuf.SetData(args);

        kernel = grassCompute.FindKernel("CSMain");
        grassCompute.GetKernelThreadGroupSizes(kernel, out threadGroupX, out _, out _);
        grassCompute.SetBuffer(kernel, "grassBuffer", grassBuffer);

        grassCompute.SetTexture(kernel, "hightMap", hightMap);



        grassCompute.SetFloat("heightScale",hightScale);
        grassCompute.SetInt("grassCount", grassCount);
        grassMaterial.SetBuffer("_GrassBuffer", grassBuffer);

        grassCompute.Dispatch(kernel, Mathf.CeilToInt(grassCount / (float)threadGroupX), 1,1);


    }

    // Update is called once per frame
    void Update()
    {
        Graphics.DrawMeshInstancedIndirect(
            grassMesh, 0, grassMaterial,
            new Bounds(Vector3.zero, new Vector3(1000,1000,1000)),
            argsBuf
        );
    }
    
    void OnDestroy()
    {
        grassBuffer?.Release();
        argsBuf?.Release();
    }
}
