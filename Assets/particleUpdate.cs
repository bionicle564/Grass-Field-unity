using System.Drawing;
using Unity.Mathematics;
using UnityEngine;

public class particleUpdate : MonoBehaviour
{
    public Texture2D hieghtMap;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 newPos = new Vector3();
        float x = transform.position.x;
        float z = transform.position.z;

        x += Time.deltaTime;
        float y = GetYForXZ(x, z);

        newPos.x = x;
        newPos.y = y;
        newPos.z = z;

        this.transform.position = newPos; 

        Shader.SetGlobalVector("_particlePosition", transform.position);
    }

    float GetYForXZ(float x, float z) 
    {
        x += 150; //bring back to 0-300
        x /= 300; //bring to 0-1
        z += 150;
        z /= 300;

        float u = (x);// * hieghtMap.width);
        float v = (z);// * hieghtMap.height);

        //Debug.Log(u + ":" + v);

        float displacement = hieghtMap.GetPixelBilinear(u, v).r;
        displacement *= 11.2f;
        displacement -= 3.9f;

        return displacement;
    }
}
