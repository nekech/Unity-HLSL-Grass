using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CpuMeshTesselation : MonoBehaviour
{
    Matrix3x3 bitToXform (float bit )
    {
        float s = bit - 0.5f;
        Vector3 c1 = new Vector3( s , -0.5f , 0);
        Vector3 c2 = new Vector3( -0.5f , -s , 0) ;
        Vector3 c3 = new Vector3 (0.5f , 0.5f , 1) ;
        return new Matrix3x3 (c1 , c2 , c3 );
    }

    
    Matrix3x3 keyToXform (int key, int bitCount )
    {
        Matrix3x3 xf = new Matrix3x3(Matrix4x4.identity);
        for (int i = 0; i < bitCount; ++i)
        {
            Matrix3x3 m = bitToXform ( key & 1);
            xf = m * xf ;
            key = key >> 1;
        }

        return xf ;
    }  
    
    Vector3 berp (Vector3[] v, Vector2 u)
    {
        return v[0] + u.x * (v[1] - v[0]) + u.y * (v[2] - v[0]) ;
    }
    // subdivision routine ( vertex position only )
    void subd (int key, int bitCount, Vector3[] v_in, out Vector3[] v_out)
    {
        v_out = new Vector3[3];

        Matrix3x3 xf = keyToXform(key, bitCount) ;

        Vector3 t = xf * new Vector3(0 , 0, 1);
        Vector2 u1 = new Vector2(t.x, t.y);

        t = xf * new Vector3(1 , 0, 1);
        Vector2 u2 = new Vector2(t.x, t.y);

        t = xf * new Vector3(0 , 1, 1);
        Vector2 u3 = new Vector2(t.x, t.y);

        v_out[0] = berp (v_in, u1);
        v_out[1] = berp (v_in, u2);
        v_out[2] = berp (v_in, u3);
    }


    public Mesh GenerateTesselationMesh(Mesh mesh, int subDivisionsCount)
    {
        Mesh newMesh = new Mesh();

        List<Vector3> newVertices = new List<Vector3>();
        List<Vector3> newNormals = new List<Vector3>();
        List<Vector4> newTangents = new List<Vector4>();
        List<int> newTriangles = new List<int>();

        for (int i = 0; i < mesh.triangles.Length / 3; ++i)
        {
            Vector3[] triangleVertices = new Vector3[3];
            triangleVertices[0] = mesh.vertices[mesh.triangles[i * 3 + 0]];
            triangleVertices[1] = mesh.vertices[mesh.triangles[i * 3 + 1]];
            triangleVertices[2] = mesh.vertices[mesh.triangles[i * 3 + 2]];

            Vector3 normal = mesh.normals[mesh.triangles[i * 3 + 0]];
            Vector4 tangent = mesh.tangents[mesh.triangles[i * 3 + 0]];

            for (int j = 0; j < Mathf.Pow(2, subDivisionsCount); ++j)
            {
                Vector3[] subVertices = new Vector3[3];
                subd(j, subDivisionsCount, triangleVertices, out subVertices);

                newTriangles.Add(newVertices.Count);
                newVertices.Add(subVertices[0]);

                newTriangles.Add(newVertices.Count);
                newVertices.Add(subVertices[1]);

                newTriangles.Add(newVertices.Count);
                newVertices.Add(subVertices[2]);

                newNormals.Add(normal);
                newNormals.Add(normal);
                newNormals.Add(normal);

                newTangents.Add(tangent);
                newTangents.Add(tangent);
                newTangents.Add(tangent);
            }
        }

        newMesh.vertices = newVertices.ToArray();
        newMesh.normals = newNormals.ToArray();
        newMesh.tangents = newTangents.ToArray();

        newMesh.triangles = newTriangles.ToArray();

        return newMesh;
    }
}
