using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class TesselateMesh : MonoBehaviour
{
    // Start is called before the first frame update

    public Mesh OriginalMesh;

    void Start()
    {
        ComputeShaderTesselation tesselation = new ComputeShaderTesselation();
        var tessellationMeshBuffers = tesselation.GenerateTesselationMesh(OriginalMesh, 5);

        Mesh newMesh = new Mesh();

        List<Vector3> vertices = new List<Vector3>();
        List<Vector3> normals = new List<Vector3>();

        foreach(var vertex in tessellationMeshBuffers.GetVerticesData())
        {
            vertices.Add(vertex.Position);
            normals.Add(vertex.Normal);
        }

        newMesh.vertices = vertices.ToArray();
        newMesh.normals = normals.ToArray();
        newMesh.triangles = tessellationMeshBuffers.GetTriangles();

        GetComponent<MeshFilter>().mesh = newMesh;
    }

    // Update is called once per frame
    void Update()
    {
    }
}
