using UnityEngine;
using UnityEngine.UI;

public class frameCounter : MonoBehaviour
{

    public Text text;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        float dt = Time.deltaTime;
        text.text = (1f / dt).ToString();
    }
}
