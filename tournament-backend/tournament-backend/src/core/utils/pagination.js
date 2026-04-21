const getPagination = (query) => {
  let page = parseInt(query.page) || 1;
  let limit = parseInt(query.limit) || 20;
  if (page < 1) page = 1;
  if (limit < 1) limit = 1;
  if (limit > 100) limit = 100;
  const offset = (page - 1) * limit;
  return { limit, offset, page };
};

const getPaginationMeta = (total, page, limit) => {
  const total_pages = Math.ceil(total / limit);
  return {
    total,
    page,
    limit,
    total_pages,
    has_next: page < total_pages,
    has_prev: page > 1,
  };
};

module.exports = { getPagination, getPaginationMeta };
