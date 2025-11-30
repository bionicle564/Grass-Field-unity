using System;
using System.Drawing;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.InputSystem;
using static UnityEngine.Rendering.DebugUI;

public class particleUpdate : MonoBehaviour
{
    public Texture2D hieghtMap;
    public float speed = 50;

    public InputAction moveAction;
    float timer;

    Vector3 moveRight;
    Vector3 moveForward;


    Vector3 startPos;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        startPos.x = transform.position.x;
        startPos.z = transform.position.z;

        moveAction = InputSystem.actions.FindAction("Move");

        Vector3 cameraPos = GameObject.FindGameObjectWithTag("MainCamera").transform.position;

        moveForward = startPos - cameraPos;
        moveForward.y = 0;
        moveForward = moveForward.normalized;

        moveRight = Vector3.Cross(moveForward, new Vector3(0, 1, 0));
        moveRight = moveRight.normalized;
        

    }
    

    // Update is called once per frame
    void Update()
    {
        timer += Time.deltaTime;
        Vector3 newPos = new Vector3();


        Vector2 moveValue = moveAction.ReadValue<Vector2>();

        this.startPos += (moveRight * (-moveValue.x * Time.deltaTime * speed)) + 
                            moveForward * (moveValue.y * Time.deltaTime * speed);
        //this.startPos.z += moveValue.y * Time.deltaTime * speed;

        Debug.Log(startPos.ToString());


        float x = startPos.x;
        float z = startPos.z;

        x += (float)Math.Sin(timer) * 4.5f;
        z += (float)Math.Cos(timer) * 4.5f;
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
        displacement -= 3.7f;

        return displacement;
    }
}
