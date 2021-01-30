using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenerateGrassTutorial : MonoBehaviour
{
    MeshBuffers grassBladeBuffers;
    MeshBuffers grassPositionsBuffers;

    public Material Material;
    public GameObject AttachObject;

    Mesh grassBladeMesh;

    Bounds grassBounds; 


    private Mesh GenerateGrassBladeMesh(int bladeSegments = 3, float height = 1.0f, float width = 1.0f)
    {
        //Declare return Mesh
        Mesh mesh = new Mesh();

        Vector3 normal = new Vector3(0, 0, -1);

        //Create lists for mesh vertices, normals, uvs, triangles
        List<Vector3> vertices = new List<Vector3>();
        List<Vector3> normals = new List<Vector3>();
        List<Vector2> uvs = new List<Vector2>();

        List<int> indexes = new List<int>();

        for (int i = 0; i < bladeSegments; ++i)
        {
            //Calculate t for uv coordinates
            float t = i / (float)bladeSegments;

            //Increase height of vertices proportion of vertices count
            float segmentHeight = height * t;
            //Decrease width of segment proportion of vertices count
            float segmentWidth = width * (1 - t);

            //Add 2 vertices to mesh vertices
            vertices.Add(new Vector3(-1* segmentWidth, segmentHeight, 0));
            vertices.Add(new Vector3(segmentWidth, segmentHeight, 0));

            normals.Add(normal);
            normals.Add(normal);

            //Add uvs coordinates for new vertices
            uvs.Add(new Vector2(t, t));
            uvs.Add(new Vector2(1 - t, t));

            //indexex of new triangle
            indexes.Add(i*2 +0);
            indexes.Add(i*2 +1);
            indexes.Add(i*2 +2);

            //if it's not a last segnet, add second triangle of segment
            if (i != bladeSegments - 1)
            {
                indexes.Add(i*2 +1);
                indexes.Add(i*2 +3);
                indexes.Add(i*2 +2);
            }
        }

        //Add peak vertex
        vertices.Add(new Vector3(0, height, 0));

        //Add peak normal
        normals.Add(normal);

        //Add peak uvs
        uvs.Add(new Vector2(0.5f, 1));

        mesh.vertices = vertices.ToArray();
        mesh.normals = normals.ToArray();
        mesh.triangles =  indexes.ToArray();
        mesh.uv = uvs.ToArray();

        return mesh;
    }

    Mesh GenerateTriangle(float width = 1.0f)
    {
        Mesh mesh = new Mesh();

        mesh.vertices = new Vector3[] {new Vector3(-1 * width/2.0f, 0, 0), new Vector3(0, 1, 0), new Vector3(1*width/2.0f, 0, 0)};
        mesh.uv = new Vector2[] {new Vector2(0, 0), new Vector2(0, 1), new Vector2(1, 1)};

        var tangent = new Vector4(0, 0, 0, 1);

        var normal = new Vector3(0, -1, 0);
        mesh.normals = new Vector3[] {normal, normal, normal};

        mesh.tangents = new Vector4[] {tangent, tangent, tangent};
        mesh.triangles =  new int[] {0, 1, 2};

        return mesh;
    }

    Mesh GeneratePlane()
    {
        Mesh mesh = new Mesh();

        mesh.vertices = new Vector3[] 
        {
            new Vector3(-1, -1, 0), new Vector3(-1, 1, 0), new Vector3(1, 1, 0),
            new Vector3(-1, -1, 0), new Vector3(1, 1, 0), new Vector3(1, -1, 0),
        };

        mesh.normals = new Vector3[] {new Vector3(0, 0, 1), new Vector3(0, 0, 1), new Vector3(0, 0, 1), new Vector3(0, 0, 1), new Vector3(0, 0, 1), new Vector3(0, 0, 1)};
        mesh.triangles =  new int[] {0, 1, 2, 3, 4, 5};

        return mesh;
    }
    

    private void Start()
    {
        grassBladeMesh = GenerateGrassBladeMesh(3, 1, 0.25f);
        //grassBladeMesh = GenerateTriangle(0.5f);
        grassBladeMesh.RecalculateTangents();
        //grassBladeMesh.RecalculateNormals();

        grassBladeBuffers = new MeshBuffers(grassBladeMesh);

        Mesh grassPlaneMesh = AttachObject.GetComponent<MeshFilter>().mesh;

        grassPositionsBuffers = new MeshBuffers(grassPlaneMesh);

        //ComputeShaderTesselation tesselation = new ComputeShaderTesselation();
        //grassPositionsBuffers = tesselation.GenerateTesselationMesh(grassPlaneMesh, 5);

        Material.SetBuffer("GrassVerticesData", grassBladeBuffers.vertices);
        Material.SetBuffer("GrassIndexes", grassBladeBuffers.triangles);

        Material.SetBuffer("GrassPositionsData", grassPositionsBuffers.vertices);
        
        grassBounds = AttachObject.GetComponent<Renderer>().bounds;
        grassBounds.Expand(new Vector3(0, 10, 0));
    }

    void Update()
    {
        Material.SetMatrix("_LocalToWorld", AttachObject.transform.localToWorldMatrix);
        Material.SetMatrix("_WorldToLocal", AttachObject.transform.worldToLocalMatrix);

        Graphics.DrawProcedural(Material, grassBounds, MeshTopology.Triangles, grassBladeBuffers.triangles.count, grassPositionsBuffers.vertices.count);
    }

}
