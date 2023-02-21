import cors from 'cors'
import express from 'express'
import * as jwt from 'jsonwebtoken'
import { postgraphile } from 'postgraphile'
import * as config from 'services/config'

const app = express()
app.use(cors())

app.use(
  postgraphile(process.env.DATABASE_URL || 'postgres://x-wishlists:x-wishlists@localhost:55432/x-wishlists', 'public', {
    watchPg: true,
    graphiql: true,
    enhanceGraphiql: true,
    jwtPgTypeIdentifier: 'public.jwt_token',
    jwtSecret: config.POSTGRAPHILE_JWT_SECRET,
    pgSettings: (req) => {
      let options = {}
      const token = req.headers.authorization?.split('Bearer ')[1]
      if (token) {
        const { user_id: userId } = jwt.verify(token!, config.POSTGRAPHILE_JWT_SECRET) as { user_id: number }
        options = { 'app.current_user_id': userId.toString() }
      }
      return {
        role: 'wishlist_user',
        ...options,
      }
    },
  }),
)

app.listen(config.PORT)
