/**
 * Copyright (c) 2003-2013 SSHTOOLS LIMITED. All Rights Reserved.
 *
 * This file contains Original Code and/or Modifications of Original Code and
 * its use is subject to the terms of the GNU Public License v3.0. You may not use
 * this file except in compliance with the license terms.
 *
 * You should have received a copy of the GNU Public License v3.0 along with this
 * software; see the file LICENSE.html.  If not, write to or contact:
 *
 * SSHTOOLS, PO BOX 9700, Langar, Nottinghamshire. NG13 9WE
 *
 * Email:     support@sshtools.com
 * 
 * WWW:       http://www.sshtools.com
 * 
 * This file has been derived from the BouncyCastle Java Crypto API
 * 
 * Copyright (c) 2000 The Legion Of The Bouncy Castle (http://www.bouncycastle.org)
 * Permission is hereby granted, free of charge, to any person obtaining a copy of 
 * this software and associated documentation files (the "Software"), to deal in 
 * the Software without restriction, including without limitation the rights to 
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
 * of the Software, and to permit persons to whom the Software is furnished to do 
 * so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all 
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *****************************************************************************/
using System;

namespace Maverick.Crypto.Digests
{
	/**
	* base implementation of MD4 family style digest as outlined in
	* "Handbook of Applied Cryptography", pages 344 - 347.
	*/
	public abstract class GeneralDigest
	{
		private byte[]  xBuf;
		private int     xBufOff;

		private long    byteCount;

		protected GeneralDigest()
		{
			xBuf = new byte[4];
			xBufOff = 0;
		}

		protected GeneralDigest(GeneralDigest t)
		{
			xBuf = new byte[t.xBuf.Length];
			Array.Copy(t.xBuf, 0, xBuf, 0, t.xBuf.Length);

			xBufOff = t.xBufOff;
			byteCount = t.byteCount;
		}

		public void update(byte inbyte)
		{
			xBuf[xBufOff++] = inbyte;

			if (xBufOff == xBuf.Length)
			{
				processWord(xBuf, 0);
				xBufOff = 0;
			}

			byteCount++;
		}

		public void update(
			byte[]  inBytes,
			int     inOff,
			int     len)
		{
			//
			// fill the current word
			//
			while ((xBufOff != 0) && (len > 0))
			{
				update(inBytes[inOff]);
				inOff++;
				len--;
			}

			//
			// process whole words.
			//
			while (len > xBuf.Length)
			{
				processWord(inBytes, inOff);

				inOff += xBuf.Length;
				len -= xBuf.Length;
				byteCount += xBuf.Length;
			}

			//
			// load in the remainder.
			//
			while (len > 0)
			{
				update(inBytes[inOff]);

				inOff++;
				len--;
			}
		}

		public void finish()
		{
			long    bitLength = (byteCount << 3);

			//
			// add the pad bytes.
			//
			update((byte)128);

			while (xBufOff != 0) update((byte)0);
			processLength(bitLength);
			processBlock();
		}

		public virtual void reset()
		{
			byteCount = 0;
			xBufOff = 0;
			for ( int i = 0; i < xBuf.Length; i++ ) xBuf[i] = 0;
		}

		protected abstract void processWord(byte[] inBytes, int inOff);
		protected abstract void processLength(long bitLength);
		protected abstract void processBlock();
		public abstract String getAlgorithmName();
		public abstract int getDigestSize();
		public abstract int doFinal(byte[] outBytes, int outOff);
	}
}