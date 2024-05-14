CREATE TABLE "users"(
"id" SERIAL PRIMARY KEY,
"user_name" VARCHAR(25) NOT NULL,
"last_visit" DATE NOT NULL DEFAULT CURRENT_DATE,
"password" VARCHAR(20),
CONSTRAINT "user_length" CHECK(LENGTH(TRIM("user_name"))>0),
CONSTRAINT "pass_length" CHECK(LENGTH("password")>=8),
CONSTRAINT "unique_user" UNIQUE("user_name")
);
CREATE TABLE "topics"(
"id" SERIAL PRIMARY KEY,
"user_id" INTEGER,
"topic_name" VARCHAR(30) NOT NULL,
"topic_description" VARCHAR(500),
CONSTRAINT "topic_length" CHECK(LENGTH(TRIM("topic_name"))>0),
CONSTRAINT "fkey_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON
DELETE SET NULL,
CONSTRAINT "unique_topic" UNIQUE("topic_name")
);
CREATE TABLE "posts"(
"id" SERIAL PRIMARY KEY,
"topic_id" INTEGER NOT NULL,
"user_id" INTEGER,
"title" VARCHAR(100) NOT NULL,
"post_content" TEXT,
"post_url" TEXT,
"posted_on" DATE NOT NULL DEFAULT CURRENT_DATE,
CONSTRAINT "fk_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE
SET NULL,
CONSTRAINT "fk_topic" FOREIGN KEY ("topic_id") REFERENCES "topics"("id") ON
DELETE CASCADE,
CONSTRAINT "post_title" CHECK(LENGTH(TRIM("title"))>0),
CONSTRAINT "post_url_content" CHECK(("post_url" IS NOT NULL AND "post_content"
IS NULL) OR ("post_url" IS NULL AND "post_content" IS NOT NULL))
);



INSERT INTO "users"("user_name")
SELECT DISTINCT ("username") FROM "bad_posts"
UNION
SELECT DISTINCT ("username") FROM "bad_comments"
UNION
SELECT REGEXP_SPLIT_TO_TABLE("upvotes",',') FROM "bad_posts"
UNION
SELECT REGEXP_SPLIT_TO_TABLE("downvotes",',') FROM "bad_posts"
;
INSERT INTO "topics"("topic_name","user_id")
SELECT DISTINCT ON ("topic") bp.topic, u.id
FROM "bad_posts" bp
JOIN "users" u
ON bp.username=u.user_name
GROUP BY 1,2
;
INSERT INTO "posts"("title","post_url","post_content","topic_id","user_id")
SELECT LEFT(b.title,100), b.url, b.text_content, t.id, u.id
FROM "bad_posts" b
JOIN "topics" t
ON b.topic=t.topic_name
JOIN "users" u
ON b.username=u.user_name
;
INSERT INTO "comments"(post_id ,user_id ,content)
SELECT
p.id, u.id, b.text_content
FROM bad_comments b
JOIN "users" u ON b.username = u.user_name
JOIN "posts" p ON p.id = b.post_id
;
INSERT INTO "votes" (post_id ,user_id ,up_vote)
SELECT t1.id, u.id, 1 AS vote
FROM (SELECT id, REGEXP_SPLIT_TO_TABLE(upvotes, ',' ) AS upvote FROM
bad_posts) t1
JOIN "users" u ON u.user_name = t1.upvote;
INSERT INTO "votes" (post_id ,user_id ,down_vote)
SELECT t1.id, u.id, -1 AS vote
FROM (SELECT id, REGEXP_SPLIT_TO_TABLE(downvotes, ',' ) AS downvote FROM
bad_posts) t1
JOIN "users" u ON u.user_name = t1.downvote;
CREATE INDEX "find_posts" ON "posts"("post_url");
CREATE TABLE "comments"(
"id" SERIAL PRIMARY KEY,
"parent_comment_id" INT DEFAULT NULL,
"user_id" INTEGER,
"post_id" INTEGER NOT NULL,
"content" TEXT NOT NULL,
"commented_on" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT "content_length" CHECK(LENGTH(TRIM("content"))>0),
CONSTRAINT "fkey_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON
DELETE SET NULL,
CONSTRAINT "fk_post" FOREIGN KEY ("post_id")REFERENCES "posts"("id") ON DELETE
CASCADE,
CONSTRAINT "parent" FOREIGN KEY ("parent_comment_id") REFERENCES
"comments"("id")
ON DELETE CASCADE
);
CREATE INDEX "parent_link" ON "comments"("parent_comment_id");
CREATE TABLE "votes"(
"id" SERIAL PRIMARY KEY,
"up_vote" INTEGER,
"down_vote" INTEGER,
"user_id" INTEGER ,
"post_id" INTEGER NOT NULL,
CONSTRAINT "fk_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE
SET NULL,
CONSTRAINT "fk_post" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE
CASCADE,
CONSTRAINT "vote_count" CHECK(("up_vote"=1 AND "down_vote" IS NULL) OR
("down_vote"=-1 AND "up_vote" IS NULL)),
CONSTRAINT "unique_vote" UNIQUE("user_id","post_id")
);
CREATE INDEX "total_votes" ON "votes"("id")
