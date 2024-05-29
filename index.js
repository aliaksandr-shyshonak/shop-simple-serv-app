import Fastify from "fastify";

const fastify = Fastify({
  logger: true,
});

fastify.all("/api/*", async function handler(request, reply) {
  return process.env.CONTAINER_REGISTRY_NAME || "Hello World";
});

try {
  await fastify.listen({ port: 3000, host: '0.0.0.0' });
} catch (err) {
  fastify.log.error(err);
  process.exit(1);
}
