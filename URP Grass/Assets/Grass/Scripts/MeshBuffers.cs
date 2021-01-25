using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

public class MeshBuffers
{
    //Interanl struct for store vertex data
    [StructLayout(LayoutKind.Sequential, Pack = 0)]
    public struct VertexData
    {
        public Vector3 Position;
        public Vector3 Normal;
        public Vector2 UV;
        public Vector4 Tangent;
        public Vector3 Binormal;

        public VertexData(Vector3 position, Vector3 normal, Vector2 uv, Vector4 tangent)
        {
            Position = position;
            Normal = normal;
            UV = uv;
            Tangent = tangent;
            Binormal = Vector3.Cross(Normal, Tangent) * Tangent.w;
        }
    }

    //ComputeBuffer for store vertices data
    public ComputeBuffer vertices {get; set;}
    //ComputeBuffer for store triangles vertices indexes
    public ComputeBuffer triangles {get; set;}
    //Size of VertexData struct
    public int VertexDataSize = sizeof(float)*3  + sizeof(float)*3 + sizeof(float)*2 + sizeof(float)*4 + sizeof(float)*3;

    public MeshBuffers(int verticesCount, int trianglesCount)
    {
        InitBuffers(verticesCount, trianglesCount);
    }
    public MeshBuffers(Mesh mesh)
    {
        InitBuffers(mesh.vertices.Length, mesh.triangles.Length);

        SetVerticesData(mesh);

        triangles.SetData(mesh.triangles);
    }

    //Initialize ComputeBuffers
    public void InitBuffers(int verticesCount, int trianglesCount)
    {
        vertices = new ComputeBuffer(verticesCount, VertexDataSize);
        triangles = new ComputeBuffer(trianglesCount, sizeof(int));
    }

    //Get VertexData from ComputeBuffer
    public VertexData[] GetVerticesData()
    {
        VertexData[] data = new VertexData[vertices.count];

        vertices.GetData(data);

        return data;
    }

    //Get vertices triangles indexes from ComputeBuffer
    public int[] GetTriangles()
    {
        int[] data = new int[triangles.count];

        triangles.GetData(data);

        return data;
    }
    
    //Fill VertexData array from mesh
    private void SetVerticesData(Mesh mesh)
    {
        VertexData[] verticesData = new VertexData[mesh.vertices.Length];

        for(int i = 0; i < mesh.vertices.Length; ++i)
        {
            verticesData[i] = new VertexData(mesh.vertices[i], mesh.normals[i], mesh.uv[i], mesh.tangents[i]);
        }

        vertices.SetData(verticesData);
    }

    //Dispose ComputeBuffers
    ~MeshBuffers()
    {
        vertices.Dispose();
        triangles.Dispose();
    }
}
