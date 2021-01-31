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

        MeshBuffers origMesh = new MeshBuffers(mesh);

        kernel = Shader.FindKernel("Tessellation");

        Shader.SetBuffer(kernel, "Vertices", newMesh.vertices);
        Shader.SetBuffer(kernel, "Triangles", newMesh.triangles);

        Shader.SetBuffer(kernel, "OrigVerticesData", origMesh.vertices);
        Shader.SetBuffer(kernel, "OrigTriangles", origMesh.triangles);

        Shader.SetInt("SubDivisionsCount", subDivisionsCount);

        uint threadGroupSize = 0;
        Shader.GetKernelThreadGroupSizes(kernel, out threadGroupSize, out _, out _);
        int threadGroups = (int) ((mesh.triangles.Length/3 + (threadGroupSize - 1)) / threadGroupSize);

        Shader.Dispatch(kernel, threadGroups, 1, 1);

        return newMesh;
    }
}
