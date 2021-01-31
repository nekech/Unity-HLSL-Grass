using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenerateGrassTutorial : MonoBehaviour
{
    //buffers with blade of grass data
    MeshBuffers grassBladeBuffers;
    //buffers with grass blades position data
    MeshBuffers grassPositionsBuffers;

    //our grass material
    public Material Material;
    //atached object where we will draw grass
    public GameObject AttachObject;

    Mesh grassBladeMesh;

    //bounds of our grass
    Bounds grassBounds; 


    //Generate mesh of grass blade
    private Mesh GenerateGrassBladeMesh(int bladeSegments = 3, float height = 1.0f, float width = 1.0f)
    {
        //Declare return Mesh
        Mesh mesh = new Mesh();

        //normal for each vertex
        Vector3 normal = new Vector3(0, 0, -1);

        //Create lists for mesh vertices, normals, uvs, indexes
        List<Vector3> vertices = new List<Vector3>();
        List<Vector3> normals = new List<Vector3>();
        List<Vector2> uvs = new List<Vector2>();

        List<int> indexes = new List<int>();

        for (int i = 0; i < bladeSegments; ++i)
        {
            //Calculate t for uv coordinates and height
            float t = i / (float)bladeSegments;

            //Increase height of vertices proportion of vertices count
            float segmentHeight = height * t;
            //Decrease width of segment proportion of vertices count
            float segmentWidth = width * (1 - t);

            //Add 2 vertices to mesh vertices
            vertices.Add(new Vector3(-1* segmentWidth, segmentHeight, 0));
            vertices.Add(new Vector3(segmentWidth, segmentHeight, 0));

            //Add normals
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

        //fill result mesh
        mesh.vertices = vertices.ToArray();
        mesh.normals = normals.ToArray();
        mesh.triangles =  indexes.ToArray();
        mesh.uv = uvs.ToArray();

        return mesh;
    }

    private void Start()
    {
        //generate mesh of grass blade
        grassBladeMesh = GenerateGrassBladeMesh(3, 1, 0.25f);
        //calculate tangents for grass blade mesh
        grassBladeMesh.RecalculateTangents();

        //get buffers with data of grass blade mesh
        grassBladeBuffers = new MeshBuffers(grassBladeMesh);

        //get mesh from attached object
        Mesh grassPlaneMesh = AttachObject.GetComponent<MeshFilter>().mesh;

        //get buffers with data of attached object mesh
        //grassPositionsBuffers = new MeshBuffers(grassPlaneMesh);

        //tessellate attached object mesh
        ComputeShaderTesselation tesselation = new ComputeShaderTesselation();
        grassPositionsBuffers = tesselation.GenerateTesselationMesh(grassPlaneMesh, 5);

        //set buffer with data of grass blade vertices
        Material.SetBuffer("GrassVerticesData", grassBladeBuffers.vertices);
        //set buffer with indexes of grass blade vertices
        Material.SetBuffer("GrassIndexes", grassBladeBuffers.triangles);

        //set buffer with data of grass blades positions
        Material.SetBuffer("GrassPositionsData", grassPositionsBuffers.vertices);
        
        //get bounds from attached object
        grassBounds = AttachObject.GetComponent<Renderer>().bounds;
        //expand bounds in oy axis
        grassBounds.Expand(new Vector3(0, 10, 0));
    }

    void Update()
    {
        //set local to world matrix from attached object
        Material.SetMatrix("_LocalToWorld", AttachObject.transform.localToWorldMatrix);
        //set world to local matrix from attached object
        Material.SetMatrix("_WorldToLocal", AttachObject.transform.worldToLocalMatrix);

        Graphics.DrawProcedural(Material, grassBounds, MeshTopology.Triangles, grassBladeBuffers.triangles.count, grassPositionsBuffers.vertices.count);
    }

}
