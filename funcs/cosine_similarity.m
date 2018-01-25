function sim = cosine_similarity (u, v)
    sim = dot(u,v)/(norm(u)*norm(v));
end
