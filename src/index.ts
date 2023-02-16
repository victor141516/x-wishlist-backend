import express from 'express'
import { postgraphile } from 'postgraphile'

const app = express()

app.use(
  postgraphile(process.env.DATABASE_URL || 'postgres://x-wishlists:x-wishlists@localhost:55432/x-wishlists', 'public', {
    watchPg: true,
    graphiql: true,
    enhanceGraphiql: true,
    pgSettings: async (req) => {
      console.log(req)
      return {
        'app.current_user_id': '2',
        role: 'wishlist_user',
      }
    },
  }),
)

app.listen(process.env.PORT || 4000)
