import asyncio, httpx, json
async def test():
    async with httpx.AsyncClient() as c:
        r = await c.post('http://localhost:8000/api/v1/chat', json={
            'message': '你好小暖，今天心情怎么样？',
            'history': []
        })
        data = r.json()
        reply = data['message']['content']
        emotion = data['emotion']
        # Print ASCII-safe summary
        print(f"Status: {r.status_code}")
        print(f"Reply length: {len(reply)} chars")
        print(f"Emotion: {emotion}")
        print(f"First 40 chars: {reply[:40]}")
asyncio.run(test())
print("Done")
