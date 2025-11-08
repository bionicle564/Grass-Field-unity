using UnityEngine;
using System.Runtime.InteropServices;
using System;
using System.Linq;

public class spawner : MonoBehaviour
{
    public Mesh grassMesh;
    public Material grassMaterial;
    public ComputeShader grassCompute;

    public Texture2D hightMap;

    public int grassCount = 1000;

    public float hightScale = 1;

    public int sideLength = 300;
    public int density = 1;

    public Camera camera;

    ComputeBuffer grassBuffer;
    ComputeBuffer argsBuf;
    ComputeBuffer countOut;

    int kernel;
    uint threadGroupX;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        uint argCount = (uint)(grassCount * density * density);
        int stride = Marshal.SizeOf(typeof(GrassData));
        grassBuffer = new ComputeBuffer(grassCount*density * density, stride, ComputeBufferType.Structured);


        uint[] args = new uint[5] {
            grassMesh.GetIndexCount(0), (uint)argCount,
            grassMesh.GetIndexStart(0), grassMesh.GetBaseVertex(0), 0
        };

        argsBuf = new ComputeBuffer(1, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);
        

        countOut = new ComputeBuffer(1, 1 * sizeof(uint), ComputeBufferType.Structured);



        kernel = grassCompute.FindKernel("CSMain");
        grassCompute.GetKernelThreadGroupSizes(kernel, out threadGroupX, out _, out _);
        grassCompute.SetBuffer(kernel, "grassBuffer", grassBuffer);

        grassCompute.SetTexture(kernel, "hightMap", hightMap);

        // set the camPosition
        grassCompute.SetVector("camPos", camera.transform.position);
        grassCompute.SetVector("camDir", camera.transform.forward);

        grassCompute.SetBuffer(kernel, "count", countOut);

        grassCompute.SetFloat("heightScale",hightScale);
        grassCompute.SetFloat("sideLength", sideLength);

        grassCompute.SetInt("density", density);

        grassCompute.SetInt("grassCount", (grassCount*density * density));

        //set the data in the material for grass rendering
        grassMaterial.SetBuffer("_GrassBuffer", grassBuffer);
        uint[] backData = new uint[1];
        backData[0] = 0;
        countOut.SetData(backData);

        grassCompute.Dispatch(kernel, Mathf.CeilToInt((grassCount * density * density) / (float)threadGroupX), 1,1);

        // get the positions back
        GrassData[] grassPreSort = new GrassData[grassCount * density * density];
        grassBuffer.GetData(grassPreSort);

        // sort based on if it should be culled
        GrassData[] grassSorted = grassPreSort.OrderByDescending(x => x.position.w).ToArray();
        //grassBuffer.Release();
        grassBuffer.SetData(grassSorted);

        
        countOut.GetData(backData);

        args[1] = backData[0];
        
        argsBuf.SetData(args);


        Debug.Log(backData[0]);

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
        countOut?.Release();
    }
}
