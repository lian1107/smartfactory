import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { type, data } = await req.json();

    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) {
      throw new Error("ANTHROPIC_API_KEY not configured");
    }

    let prompt = "";
    if (type === "project") {
      prompt = `你是一个智能工厂管理助手。请分析以下项目数据，用中文给出简洁的进度评估、风险提示和改善建议（3-5句话）：\n${JSON.stringify(data, null, 2)}`;
    } else if (type === "production") {
      prompt = `你是一个智能工厂管理助手。请分析以下生产数据，用中文给出简洁的质量趋势分析和改善建议（3-5句话）：\n${JSON.stringify(data, null, 2)}`;
    } else {
      throw new Error(`Unknown analysis type: ${type}`);
    }

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 400,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Claude API error: ${errText}`);
    }

    const result = await response.json();
    const summary = result.content?.[0]?.text ?? "分析暂时不可用";

    return new Response(JSON.stringify({ summary }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
