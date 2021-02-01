using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeShaderTesselation
{
    //Load compute shader from resources
    public ComputeShader Shader = (ComputeShader)Resources.Load("Tessellation");
    //define kernel handle
    int kernel;
    
    public MeshBuffers GenerateTesselationMesh(Mesh mesh, int subDivisionsLevel)
    {
        //calculate number of new trianggles per each triangle
        int subCoef = (int)Mathf.Pow(2, subDivisionsLevel);

        //define buffers for new tessellate mesh
        MeshBuffers newMesh = new MeshBuffers(mesh.triangles.Length * subCoef, mesh.triangles.Length * subCoef);

        //get buffers for original buffers
        MeshBuffers origMesh = new MeshBuffers(mesh);

        //get handle to kernel in our tessellation shader
        kernel = Shader.FindKernel("Tessellation");

        //set buffer with new mesh vertices data
        Shader.SetBuffer(kernel, "Vertices", newMesh.vertices);
        //set buffer for new mesh triangles indexes
        Shader.SetBuffer(kernel, "Triangles", newMesh.triangles);

        //set buffer with original mesh vertices data
        Shader.SetBuffer(kernel, "OrigVerticesData", origMesh.vertices);
        //set buffer with original mesh triangles
        Shader.SetBuffer(kernel, "OrigTriangles", origMesh.triangles);

        //set subdivision coefficient
        Shader.SetInt("SubDivisionsLevel", subDivisionsLevel);
 
        uint threadGroupSize = 0;
        //get number of threads from tessellation shader
        Shader.GetKernelThreadGroupSizes(kernel, out threadGroupSize, out _, out _);
        //compute count of threads group
        int threadGroups = (int) ((mesh.triangles.Length/3 + (threadGroupSize - 1)) / threadGroupSize);

        //call our tessellation shader
        Shader.Dispatch(kernel, threadGroups, 1, 1);

        return newMesh;
    }
}
