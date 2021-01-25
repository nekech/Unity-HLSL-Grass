using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeShaderTesselation
{
    public ComputeShader Shader = (ComputeShader)Resources.Load("Tessellation");
    int kernel;
    
    public MeshBuffers GenerateTesselationMesh(Mesh mesh, int subDivisionsCount)
    {
        int subCoef = (int)Mathf.Pow(2, subDivisionsCount);

        MeshBuffers newMesh = new MeshBuffers(mesh.triangles.Length * subCoef, mesh.triangles.Length * subCoef);

        ComputeBuffer OrigVertices = new ComputeBuffer(mesh.vertices.Length, sizeof(float) * 3);
        OrigVertices.SetData(mesh.vertices);

        ComputeBuffer OrigNormals = new ComputeBuffer(mesh.normals.Length, sizeof(float) * 3);
        OrigNormals.SetData(mesh.normals);

        ComputeBuffer OrigTangents = new ComputeBuffer(mesh.tangents.Length, sizeof(float) * 4);
        OrigTangents.SetData(mesh.tangents);

        ComputeBuffer OrigTriangles = new ComputeBuffer(mesh.triangles.Length, sizeof(int));
        OrigTriangles.SetData(mesh.triangles);


        kernel = Shader.FindKernel("Tessellation");

        Shader.SetBuffer(kernel, "Vertices", newMesh.vertices);
        Shader.SetBuffer(kernel, "Triangles", newMesh.triangles);

        Shader.SetBuffer(kernel, "OrigVertices", OrigVertices);
        Shader.SetBuffer(kernel, "OrigNormals", OrigNormals);
        Shader.SetBuffer(kernel, "OrigTangents", OrigTangents);
        Shader.SetBuffer(kernel, "OrigTriangles", OrigTriangles);

        Shader.SetInt("SubDivisionsCount", subDivisionsCount);

        uint threadGroupSize = 0;
        Shader.GetKernelThreadGroupSizes(kernel, out threadGroupSize, out _, out _);
        int threadGroups = (int) ((mesh.triangles.Length/3 + (threadGroupSize - 1)) / threadGroupSize);

        Shader.Dispatch(kernel, threadGroups, 1, 1);

        return newMesh;
    }
}
