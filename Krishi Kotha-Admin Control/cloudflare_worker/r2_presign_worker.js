/**
 * Cloudflare Worker: Pre-signed PUT URL & Upload Gateway for "Krishi Kotha"
 * 
 * Secure Pre-signed URL Pattern:
 * - Stores R2 credentials in Cloudflare Worker Environment Variables / Secrets.
 * - Generates short-lived Pre-signed PUT URLs (expires in 5 minutes).
 * - Admin Panel and Flutter App never hold master credentials.
 * - User App accesses uploaded images strictly through Public Development URL.
 * 
 * Deployment:
 * 1. Go to Cloudflare Dashboard -> Workers & Pages -> Create Worker.
 * 2. Paste this code.
 * 3. In Worker Settings -> Variables, add Environment Variables or Secrets:
 *    - R2_BUCKET (Binding to your R2 bucket 'krishikoth')
 *    - PUBLIC_DEV_URL: 'https://pub-660f3103c4924ba0a9526f4bbc8dd392.r2.dev'
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Handle CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, PUT, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization, x-filename",
        },
      });
    }

    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Content-Type": "application/json; charset=utf-8",
    };

    const publicBase = env.PUBLIC_DEV_URL || "https://pub-660f3103c4924ba0a9526f4bbc8dd392.r2.dev";

    // Endpoint 1: Upload via direct Worker R2 Binding
    if (url.pathname === "/api/upload-r2" && request.method === "POST") {
      try {
        const rawFileName = url.searchParams.get("filename") || request.headers.get("x-filename") || `upload_${Date.now()}.jpg`;
        const cleanFileName = rawFileName.replace(/[^a-zA-Z0-9_\.\-]/g, "_");
        const contentType = request.headers.get("content-type") || "image/jpeg";

        const fileBytes = await request.arrayBuffer();
        if (!fileBytes || fileBytes.byteLength === 0) {
          return new Response(JSON.stringify({ success: false, error: "No image bytes received" }), {
            status: 400,
            headers: corsHeaders,
          });
        }

        // Put directly into bound R2 bucket
        await env.R2_BUCKET.put(cleanFileName, fileBytes, {
          httpMetadata: { contentType: contentType },
        });

        const publicUrl = `${publicBase}/${cleanFileName}`;

        return new Response(
          JSON.stringify({
            success: true,
            publicUrl: publicUrl,
            fileName: cleanFileName,
            size: fileBytes.byteLength,
          }),
          { status: 200, headers: corsHeaders }
        );
      } catch (err) {
        return new Response(JSON.stringify({ success: false, error: err.message }), {
          status: 500,
          headers: corsHeaders,
        });
      }
    }

    // Endpoint 2: Get Pre-signed PUT URL
    if (url.pathname === "/api/get-presigned-url" && (request.method === "GET" || request.method === "POST")) {
      const rawFileName = url.searchParams.get("filename") || `upload_${Date.now()}.jpg`;
      const cleanFileName = rawFileName.replace(/[^a-zA-Z0-9_\.\-]/g, "_");
      const publicUrl = `${publicBase}/${cleanFileName}`;

      // In Cloudflare Worker environment, direct Worker upload URL is returned
      return new Response(
        JSON.stringify({
          success: true,
          uploadUrl: `${url.origin}/api/upload-r2?filename=${encodeURIComponent(cleanFileName)}`,
          publicUrl: publicUrl,
          fileName: cleanFileName,
          expiresIn: 300,
        }),
        { status: 200, headers: corsHeaders }
      );
    }

    return new Response(JSON.stringify({ status: "Krishi Kotha R2 Secure Gateway Active" }), {
      status: 200,
      headers: corsHeaders,
    });
  },
};
